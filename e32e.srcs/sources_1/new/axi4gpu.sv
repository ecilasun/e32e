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

logic [14:0] fbwa;
logic [31:0] fbdin;
logic [3:0] fbwe0 = 4'h0;
logic [3:0] fbwe1 = 4'h0;

logic hsync_d, vsync_d, blank_d;
logic [23:0] paletteout_d;

// Framebuffer select
logic writepage = 1'b0;
logic writepage_d = 1'b0;

wire out_tmds_red;
wire out_tmds_green;
wire out_tmds_blue;
wire out_tmds_clk;

// Address setup for cached words on next scanline
wire [9:0] pix_x = video_x[10:1];
wire [9:0] pix_y = video_y[10:1];

// Byte address of current pixel
wire [16:0] fbra = pix_y[7:0]*320 + pix_x[8:0]; // y*320 + x

// Scan-out from the page we're not writing to
wire [7:0] fbdout0;
wire [7:0] fbdout1;

// ----------------------------------------------------------------------------
// Framebuffer
// ----------------------------------------------------------------------------

framebuffer FB0(
	// Input from uncached bus
	.addra(fbwa),
	.clka(aclk),
	.dina(fbdin),
	.wea(fbwe0),
	.ena( (|fbwe0) ),
	// Output to scanline fifo
	.addrb(fbra),
	.clkb(pixelclock),
	.doutb(fbdout0),
	.enb((~blank_d) & writepage_d) );

framebuffer FB1(
	// Input from uncached bus
	.addra(fbwa),
	.clka(aclk),
	.dina(fbdin),
	.wea(fbwe1),
	.ena( (|fbwe1) ),
	// Output to scanline fifo
	.addrb(fbra),
	.clkb(pixelclock),
	.doutb(fbdout1),
	.enb((~blank_d) & (~writepage_d)) );

// ----------------------------------------------------------------------------
// Color palette
// ----------------------------------------------------------------------------

logic palettewe = 1'b0;
logic [7:0] palettewa = 8'h00;
logic [23:0] palettedin = 24'h000000;

// Look up the palette data with based on which framebuffer has scanout
wire [7:0] palettera = writepage_d ? fbdout0 : fbdout1;

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
	writepage_d <= writepage;
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
						default/*4'h0*/: begin // fb0 / fb1 depending on writepage
							fbdin <= s_axi.wdata[31:0];
							if (writepage) // Write to FB1
								fbwe1 <= s_axi.wstrb[3:0];
							else // Write to FB0
								fbwe0 <= s_axi.wstrb[3:0];
						end
						4'h2: begin // pal
							palettedin <= s_axi.wdata[23:0];
							palettewe <= 1'b1;
						end
						4'h4: begin // ctl
							writepage <= s_axi.wdata[0];
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
					s_axi.arready <= 1'b1;
					raddrstate <= 2'b01;
				end
			end
			default/*2'b01*/: begin
				if (s_axi.rready) begin
					s_axi.rdata[31:0] <= 32'd0; // Nothing to read here
					s_axi.rvalid <= 1'b1;
					raddrstate <= 2'b00;
				end
			end
		endcase
	end
end

endmodule
