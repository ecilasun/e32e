`timescale 1ns / 1ps

module axi4gpu(
	input wire aclk,
	input wire aresetn,
	input wire pixelclock,
	input wire videoclock,
	axi_if.slave axi4if,
	gpudataoutput.def gpudata );

// ----------------------------------------------------------------------------
// Wires
// ----------------------------------------------------------------------------

wire hsync, vsync, blank;
wire [10:0] video_x;
wire [10:0] video_y;

logic [14:0] fbwa;
logic [31:0] fbdin;
logic [3:0] fbwe = 4'h0;

wire out_tmds_red;
wire out_tmds_green;
wire out_tmds_blue;
wire out_tmds_clk;

// Address setup for cached words on next scanline
wire [9:0] pix_x = video_x[10:1];
wire [9:0] pix_y = video_y[10:1];

// Byte address of current pixel
wire [16:0] fbra = pix_y[7:0]*320 + pix_x[8:0]; // y*320 + x
wire [7:0] fbdout;

// ----------------------------------------------------------------------------
// Framebuffer
// ----------------------------------------------------------------------------

framebuffer FB0(
	// Input from uncached bus
	.addra(fbwa),
	.clka(aclk),
	.dina(fbdin),
	.wea(fbwe),
	.ena( (|fbwe) ),
	// Output to scanline fifo
	.addrb(fbra),
	.clkb(pixelclock),
	.doutb(fbdout),
	.enb(~blank) );

// ----------------------------------------------------------------------------
// Color palette
// ----------------------------------------------------------------------------

logic palettewe = 1'b0;
logic [7:0] palettewa = 8'h00;
logic [23:0] palettedin = 24'h000000;

wire [7:0] palettera;
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

logic hsync_d, vsync_d, blank_d;
logic [23:0] paletteout_d;
always @(posedge pixelclock) begin
	hsync_d <= hsync;
	vsync_d <= vsync;
	blank_d <= blank;
	paletteout_d <= paletteout;
end

// ----------------------------------------------------------------------------
// HDMI output
// ----------------------------------------------------------------------------

// Byte select from current word
assign palettera = fbdout[7:0];

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

logic [1:0] waddrstate = 2'b00;
logic [1:0] writestate = 2'b00;
logic [1:0] raddrstate = 2'b00;

always @(posedge aclk) begin
	if (~aresetn) begin
		axi4if.awready <= 1'b0;
	end else begin
		// write address
		case (waddrstate)
			2'b00: begin
				if (axi4if.awvalid) begin
					fbwa <= axi4if.awaddr[16:2];
					axi4if.awready <= 1'b1;
					waddrstate <= 2'b01;
				end
			end
			default/*2'b01*/: begin
				axi4if.awready <= 1'b0;
				waddrstate <= 2'b00;
			end
		endcase
	end
end

always @(posedge aclk) begin
	if (~aresetn) begin
		axi4if.wready <= 1'b0;
	end else begin
		// write data
		fbwe <= 4'h0;
		palettewe <= 1'b0;
		case (writestate)
			2'b00: begin
				if (axi4if.wvalid) begin
					// fb0: @81000000 // axi4if.awaddr[19:16] == 0 [+]
					// fb1: @81020000 // axi4if.awaddr[19:16] == 2 [ ]
					// pal: @81040000 // axi4if.awaddr[19:16] == 4 [+]
					// ctl: @81080000 // axi4if.awaddr[19:16] == 8 [ ]
					case (axi4if.awaddr[19:16])
						default/*4'h0*/: begin // fb0
							fbdin <= axi4if.wdata[31:0];
							fbwe <= axi4if.wstrb[3:0];
						end
						4'h4: begin // pal
							palettewa <= axi4if.awaddr[9:2]; // word aligned
							palettedin <= axi4if.wdata[23:0];
							palettewe <= 1'b1;
						end
					endcase
					axi4if.wready <= 1'b1;
					writestate <= 2'b01;
				end
			end
			2'b01: begin
				axi4if.wready <= 1'b0;
				if(axi4if.bready) begin
					axi4if.bvalid <= 1'b1;
					axi4if.bresp = 2'b00; // okay
					writestate <= 2'b10;
				end
			end
			default/*2'b10*/: begin
				axi4if.bvalid <= 1'b0;
				writestate <= 2'b00;
			end
		endcase
	end
end

always @(posedge aclk) begin
	if (~aresetn) begin
		axi4if.arready <= 1'b0;
		axi4if.rvalid <= 1'b0;
		axi4if.rresp <= 2'b00;
	end else begin
		// read address
		//re <= 1'b0;
		case (raddrstate)
			2'b00: begin
				if (axi4if.arvalid) begin
					axi4if.arready <= 1'b1;
					//re <= 1'b1;
					raddrstate <= 2'b01;
				end
			end
			2'b01: begin
				axi4if.arready <= 1'b0;
				// master ready to accept
				if (axi4if.rready ) begin
					axi4if.rdata[31:0] <= 32'd0; // Nothing to read here
					axi4if.rvalid <= 1'b1;
					//axi4if.rlast <= 1'b1; // last in burst
					raddrstate <= 2'b10; // delay one clock for master to pull down arvalid
				end
			end
			default/*2'b10*/: begin
				// at this point master should have responded properly with arvalid=0
				axi4if.rvalid <= 1'b0;
				//axi4if.rlast <= 1'b0;
				raddrstate <= 2'b00;
			end
		endcase
	end
end

endmodule
