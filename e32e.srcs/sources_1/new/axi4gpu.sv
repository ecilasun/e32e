`timescale 1ns / 1ps

module axi4gpu(
	input wire aclk,
	input wire aresetn,
	input wire pixelclock,
	input wire videoclock,
	axi_if.slave s_axi,
	gpudataoutput.def gpudata );

// ----------------------------------------------------------------------------
// Wires
// ----------------------------------------------------------------------------

wire hsync, vsync, blank;
wire [10:0] video_x;
wire [10:0] video_y;

logic [14:0] fbra = 0;
logic [14:0] fbwa = 0;
logic [31:0] fbdin = 0;
wire [31:0] fbdouta;
wire [31:0] fbdoutb;
logic [3:0] fbwe0 = 4'h0;
logic [3:0] fbwe1 = 4'h0;

logic hsync_d, vsync_d, blank_d;
logic [23:0] paletteout_d;

// CPU/GPU framebuffer select
// By default, CPU can r/w to page #0, and GPU scans out from page #1
logic cpupage = 1'b0;
logic scanpage = 1'b1;
logic scanpage_d = 1'b1;

wire out_tmds_red;
wire out_tmds_green;
wire out_tmds_blue;
wire out_tmds_clk;

// Address setup for cached words on next scanline
wire [9:0] pix_x = video_x[10:1];
wire [9:0] pix_y = video_y[10:1];

// Byte address of current pixel
wire [16:0] fbscana = pix_y[7:0]*320 + pix_x[8:0]; // y*320 + x

// Scan-out from the page we're not writing to
wire [7:0] fbscanout0;
wire [7:0] fbscanout1;

// ----------------------------------------------------------------------------
// Framebuffer
// ----------------------------------------------------------------------------

framebuffer FB0(
	// CPU read/write channel
	.addra((|fbwe0) ? fbwa : fbra),
	.clka(aclk),
	.dina(fbdin),
	.douta(fbdouta),
	.ena( ~cpupage ),		// Always accessible when selected
	.wea(fbwe0),
	// Scan-out and spare write access channel
	.addrb(fbscana),
	.clkb(pixelclock),
	.dinb(),				// TODO: Reserved
	.doutb(fbscanout0),
	.enb( ~scanpage_d ),	// Always accessible when selected
	.web(4'h0) );			// TODO: Reserved

framebuffer FB1(
	// CPU read/write channel
	.addra((|fbwe1) ? fbwa : fbra),
	.clka(aclk),
	.dina(fbdin),
	.douta(fbdoutb),
	.ena( cpupage ),		// Always accessible when selected
	.wea(fbwe1),
	// Scan-out and spare write access channel
	.addrb(fbscana),
	.clkb(pixelclock),
	.dinb(),				// TODO: Reserved
	.doutb(fbscanout1),
	.enb( scanpage_d ),		// Always accessible when selected
	.web(4'h0) );			// TODO: Reserved

// ----------------------------------------------------------------------------
// Color palette
// ----------------------------------------------------------------------------

logic palettewe = 1'b0;
logic [7:0] palettewa = 8'h00;
logic [23:0] palettedin = 24'h000000;

// CPU r/w and scan-out pages are controlled individually
wire [7:0] palettera = scanpage_d ? fbscanout1 : fbscanout0;

logic [23:0] paletteentries[0:255];

// Set up with VGA color palette on startup
initial begin
	$readmemh("colorpalette.mem", paletteentries);
end

always @(posedge aclk) begin // Tied to GPU clock
	if (palettewe)
		paletteentries[palettewa] <= palettedin;
end

wire [23:0] paletteout;
assign paletteout = paletteentries[palettera];

// ----------------------------------------------------------------------------
// One clock (half pixel) delay
// ----------------------------------------------------------------------------

always @(posedge pixelclock) begin
	hsync_d <= hsync;
	vsync_d <= vsync;
	blank_d <= blank;
	scanpage_d <= scanpage;
	paletteout_d <= paletteout;
end

// ----------------------------------------------------------------------------
// HDMI output
// ----------------------------------------------------------------------------

my_vga_clk_generator VGAClkGen(
   .pclk(pixelclock),
   .out_hsync(hsync),
   .out_vsync(vsync),
   .out_blank(blank),
   .out_hcnt(video_x),
   .out_vcnt(video_y),
   .reset_n(aresetn) );

hdmi_device HDMI(
   .pclk(pixelclock),
   .tmds_clk(videoclock), // pixelclockx10

   .in_vga_red(paletteout_d[15:8]),
   .in_vga_green(paletteout_d[23:16]),
   .in_vga_blue(paletteout_d[7:0]),

   .in_vga_blank(blank_d),
   .in_vga_vsync(vsync_d),
   .in_vga_hsync(hsync_d),

   .out_tmds_red(out_tmds_red),
   .out_tmds_green(out_tmds_green),
   .out_tmds_blue(out_tmds_blue),
   .out_tmds_clk(out_tmds_clk) );

// Output buffers for differential signals
OBUFDS OBUFDS_clock  (.I(out_tmds_clk),    .O(gpudata.tmdsclkp), .OB(gpudata.tmdsclkn));
OBUFDS OBUFDS_red    (.I(out_tmds_red),    .O(gpudata.tmdsp[2]), .OB(gpudata.tmdsn[2]));
OBUFDS OBUFDS_green  (.I(out_tmds_green),  .O(gpudata.tmdsp[1]), .OB(gpudata.tmdsn[1]));
OBUFDS OBUFDS_blue   (.I(out_tmds_blue),   .O(gpudata.tmdsp[0]), .OB(gpudata.tmdsn[0]));

// ----------------------------------------------------------------------------
// GPU state machine
// ----------------------------------------------------------------------------

logic [1:0] writestate = 2'b00;
logic [1:0] raddrstate = 2'b00;

always @(posedge aclk) begin
	if (~aresetn) begin
		s_axi.awready <= 1'b0;
	end else begin
		s_axi.awready <= 1'b0;
		if (s_axi.awvalid) begin
			fbwa <= s_axi.awaddr[16:2];
			palettewa <= s_axi.awaddr[9:2];
			s_axi.awready <= 1'b1;
		end
	end
end

always @(posedge aclk) begin
	if (~aresetn) begin
		s_axi.wready <= 1'b0;
		s_axi.bvalid <= 1'b0;
	end else begin
		// write data
		fbwe0 <= 4'h0;
		fbwe1 <= 4'h0;
		palettewe <= 1'b0;
		s_axi.wready <= 1'b0;
		s_axi.bvalid <= 1'b0;
		case (writestate)
			2'b00: begin
				if (s_axi.wvalid) begin
					// fb0/1: @81000000 // s_axi.awaddr[19:16] == 0 [+]
					// pal:   @81020000 // s_axi.awaddr[19:16] == 2 [+]
					// ctl:   @81040000 // s_axi.awaddr[19:16] == 4 [+]
					case (s_axi.awaddr[19:16])
						default/*4'h0*/: begin // fb0 / fb1 depending on cpupage
							fbdin <= s_axi.wdata[31:0];
							if (cpupage) // Write to FB1
								fbwe1 <= s_axi.wstrb[3:0];
							else // Write to FB0
								fbwe0 <= s_axi.wstrb[3:0];
						end
						4'h2: begin // pal
							palettedin <= s_axi.wdata[23:0];
							palettewe <= 1'b1;
						end
						4'h4: begin // ctl: write and read page selection
							cpupage <= s_axi.wdata[0];	// 0: FB0, 1: FB1
							scanpage <= s_axi.wdata[1];	// 0: FB0, 1: FB1
						end
					endcase
					s_axi.wready <= 1'b1;
					writestate <= 2'b01;
				end
			end
			default/*2'b01*/: begin
				if(s_axi.bready) begin
					s_axi.bvalid <= 1'b1;
					s_axi.bresp = 2'b00; // okay
					writestate <= 2'b00;
				end
			end
		endcase
	end
end

always @(posedge aclk) begin
	if (~aresetn) begin
		s_axi.rlast <= 1'b1;
		s_axi.arready <= 1'b0;
		s_axi.rvalid <= 1'b0;
		s_axi.rresp <= 2'b00;
	end else begin
		s_axi.rvalid <= 1'b0;
		s_axi.arready <= 1'b0;
		case (raddrstate)
			2'b00: begin
				if (s_axi.arvalid) begin
					fbra <= s_axi.araddr[16:2];
					s_axi.arready <= 1'b1;
					raddrstate <= 2'b01;
				end
			end
			default/*2'b01*/: begin
				if (s_axi.rready) begin
					if (cpupage) // Read from FB1
						s_axi.rdata[31:0] <= fbdouta;
					else // Read from FB0
						s_axi.rdata[31:0] <= fbdoutb;
					s_axi.rvalid <= 1'b1;
					raddrstate <= 2'b00;
				end
			end
		endcase
	end
end

endmodule
