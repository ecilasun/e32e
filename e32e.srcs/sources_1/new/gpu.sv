`timescale 1ns / 1ps

module gpu(
	input wire aclk,
	input wire clk25,
	input wire clk250,
	input wire aresetn,
	axi_if.master m_axi,
	gpudataoutput.def gpudata,
	input wire gpufifoempty,
	input wire [31:0] gpufifodout,
	output wire gpufifore,
	input wire gpufifovalid );

wire hsync, vsync, blank;
wire [10:0] video_x;
wire [10:0] video_y;

logic hsync_d, vsync_d, blank_d;
logic [23:0] paletteout_d;

wire out_tmds_red;
wire out_tmds_green;
wire out_tmds_blue;
wire out_tmds_clk;

logic cmdre = 1'b0;
assign gpufifore = cmdre;

// ------------------------------------------------------------------------------------
// Scanline cache and output address selection
// ------------------------------------------------------------------------------------

logic [127:0] scanlinecache [0:31]; // scanline cache (only 20 128bits used)

logic palettewe = 1'b0;
logic [7:0] palettewa = 8'h00;
logic [23:0] palettedin = 24'h000000;

logic [7:0] palettera;
always_comb begin
	case (video_x[4:1])
		4'b0000: palettera = scanlinecache[video_x[9:5]][7 : 0];
		4'b0001: palettera = scanlinecache[video_x[9:5]][15 : 8];
		4'b0010: palettera = scanlinecache[video_x[9:5]][23 : 16];
		4'b0011: palettera = scanlinecache[video_x[9:5]][31 : 24];
		4'b0100: palettera = scanlinecache[video_x[9:5]][39 : 32];
		4'b0101: palettera = scanlinecache[video_x[9:5]][47 : 40];
		4'b0110: palettera = scanlinecache[video_x[9:5]][55 : 48];
		4'b0111: palettera = scanlinecache[video_x[9:5]][63 : 56];
		4'b1000: palettera = scanlinecache[video_x[9:5]][71 : 64];
		4'b1001: palettera = scanlinecache[video_x[9:5]][79 : 72];
		4'b1010: palettera = scanlinecache[video_x[9:5]][87 : 80];
		4'b1011: palettera = scanlinecache[video_x[9:5]][95 : 88];
		4'b1100: palettera = scanlinecache[video_x[9:5]][103 : 96];
		4'b1101: palettera = scanlinecache[video_x[9:5]][111 : 104];
		4'b1110: palettera = scanlinecache[video_x[9:5]][119 : 112];
		4'b1111: palettera = scanlinecache[video_x[9:5]][127 : 120];
	endcase
end

// ------------------------------------------------------------------------------------
// Palette RAM
// ------------------------------------------------------------------------------------

logic [23:0] paletteentries[0:255];

initial begin
	$readmemh("colorpalette.mem", paletteentries);
end

always @(posedge aclk) begin // Tied to GPU clock
	if (palettewe)
		paletteentries[palettewa] <= palettedin;
end

wire [23:0] paletteout;
assign paletteout = paletteentries[palettera];

// ------------------------------------------------------------------------------------
// Video signals
// ------------------------------------------------------------------------------------

my_vga_clk_generator VGAClkGen(
   .pclk(clk25),
   .out_hsync(hsync),
   .out_vsync(vsync),
   .out_blank(blank),
   .out_hcnt(video_x),
   .out_vcnt(video_y),
   .reset_n(aresetn) );

always @(posedge clk25) begin
	hsync_d <= hsync;
	vsync_d <= vsync;
	blank_d <= blank;
	paletteout_d <= paletteout;
end

hdmi_device HDMI(
   .pclk(clk25),
   .tmds_clk(clk250), // pixelclockx10

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

localparam burstlen = 20; // need to do 20x128bit reads per row, times 240 rows, 4800 reads total

assign m_axi.arlen = burstlen - 1;
assign m_axi.arsize = SIZE_16_BYTE; // 128bit read bus
assign m_axi.arburst = BURST_INCR;

assign m_axi.awlen = burstlen - 1;
assign m_axi.awsize = SIZE_16_BYTE; // 128bit write bus
assign m_axi.awburst = BURST_INCR;

// NOTE: This unit does not write to memory yet
// TODO: Will do so when raster unit is online
assign m_axi.awvalid = 0;
assign m_axi.awaddr = 'd0;
assign m_axi.wvalid = 0;
assign m_axi.wstrb = 16'h0000; // For raster unit, this will be the write mask
assign m_axi.wlast = 0;
assign m_axi.wdata = 'd0;
assign m_axi.bready = 0;

typedef enum logic [2:0] {DETECTSCANLINEEND, STARTLOAD, TRIGGERBURST, DATABURST} scanstatetype;
scanstatetype scanstate = DETECTSCANLINEEND;

// NOTE: First, set up the scanout address, then enable video scanout
logic [31:0] scanaddr = 32'h00000000;
logic [31:0] scanoffset = 0;
logic scanenable = 1'b0;

logic [4:0] rdata_cnt = 0;

// ------------------------------------------------------------------------------------
// Command FIFO
// ------------------------------------------------------------------------------------

typedef enum logic [2:0] {
	WCMD, DISPATCH,
	SETVPAGE,
	SETPAL,
	VMODE,
	//DMASOURCE,
	//DMATARGET,
	//DMAKICK,
	FINALIZE } gpucmdmodetype;
gpucmdmodetype cmdmode = WCMD;

logic [31:0] gpucmd = 'd0;

always_ff @(posedge aclk) begin
	if (~aresetn) begin
		cmdmode <= WCMD;
	end else begin

		cmdre <= 1'b0;
		palettewe <= 1'b0;

		case (cmdmode)
			WCMD: begin
				if (gpufifovalid && ~gpufifoempty) begin
					gpucmd <= gpufifodout;
					// Advance FIFO
					cmdre <= 1'b1;
					// Dispatch cmd
					cmdmode <= DISPATCH;
				end
			end

			DISPATCH: begin
				case (gpucmd)
					32'h00000000:	cmdmode <= SETVPAGE;	// Set the scanout start address (followed by 32bit cached memory address, 64 byte aligned)
					32'h00000001:	cmdmode <= SETPAL;		// Set 24 bit color palette entry (followed by 8bit address+24bit color in next word)
					32'h00000002:	cmdmode <= VMODE;		// Set up video mode or turn off scan logic (default is 320x240*8bit paletted)
					// TODO: Primitive binning/setup, sprite draw, LBVH hit tests or anything else that makes sense to have here
					//32'h00000003:	cmdmode <= DMASOURCE;	// Set up source address for DMA
					//32'h00000004:	cmdmode <= DMATARGET;	// Set up target address for DMA
					//32'h00000005:	cmdmode <= DMAKICK;		// Queue up a DMA operation (optionally zero-masked)
					default:		cmdmode <= FINALIZE;	// Invalid command, wait one clock and try next
				endcase
			end

			SETVPAGE: begin
				if (gpufifovalid && ~gpufifoempty) begin
					scanaddr <= gpufifodout;	// Set new video scanout address (16 byte aligned, as we read in bursts)
					// Advance FIFO
					cmdre <= 1'b1;
					cmdmode <= FINALIZE;
				end
			end

			SETPAL: begin
				if (gpufifovalid && ~gpufifoempty) begin
					palettewe <= 1'b1;
					palettewa <= gpufifodout[31:24];	// 8 bit palette index
					palettedin <= gpufifodout[23:0];	// 24 bit color
					// Advance FIFO
					cmdre <= 1'b1;
					cmdmode <= FINALIZE;
				end
			end

			VMODE: begin
				if (gpufifovalid && ~gpufifoempty) begin
					scanenable <= gpufifodout[0]; // [0]: video output enabled when high
					// rgb_vs_pal <= gpufifodout[1]; // select 16bit RGB mode when high vs 8bit paletted mode when low
					// ? <= gpufifodout[31:2] unused for now
					// Advance FIFO
					cmdre <= 1'b1;
					cmdmode <= FINALIZE;
				end
			end
			
			/*DMASOURCE: begin
			end
			DMATARGET: begin
			end
			DMAKICK: begin
			end*/

			FINALIZE: begin
				cmdmode <= WCMD;
			end

		endcase
	end
end

// ------------------------------------------------------------------------------------
// Scan-out logic
// ------------------------------------------------------------------------------------

// domain cross
(* async_reg = "true" *) logic [8:0] scanlinepre = 'd0;
(* async_reg = "true" *) logic [8:0] scanline = 'd0;
(* async_reg = "true" *) logic [9:0] scanpixelpre = 'd0;
(* async_reg = "true" *) logic [9:0] scanpixel = 'd0;
always_ff @(posedge aclk) begin
	if (~aresetn) begin
		//
	end else begin
		scanlinepre <= video_y[8:0];
		scanline <= scanlinepre;
		scanpixelpre <= video_x[9:0];
		scanpixel <= scanpixelpre;
	end
end

always_ff @(posedge aclk) begin
	if (~aresetn) begin
		// Read
		m_axi.arvalid <= 0;
		m_axi.rready <= 0;
		scanstate <= DETECTSCANLINEEND;
	end else begin
		case (scanstate)
			DETECTSCANLINEEND: begin
				// NOTE: when scanpixel is at 638, the scan beam is at 640
				if (scanpixel == 638 && scanline < 480 && ~scanline[0]) begin // Only at right edge of screen, at even lines, and above bottommost pixel
					// Starting at 640, we have 160 pixels worth of time to load the scanline cache for next row
					// It currently takes approximately 5 pixels worth of time to load 320 pixels from block ram into scanline cache and reach here
					// For example, if we wanted to read 64 32 pixel wide sprites per scanline that'd take 30 pixels worth of time as a burst
					// which could be held by a sprite composite buffer for a scanline (excluding composite offset)
					scanoffset <= scanline[8:1]*320; // y*320 + 0, actually should be (y+1)*320 but it doesn't really matter TODO: 320 comes from videomode
					scanstate <= scanenable ? STARTLOAD : DETECTSCANLINEEND;
				end else
					scanstate <= DETECTSCANLINEEND;
			end
			STARTLOAD: begin
				rdata_cnt <= 0;
				// This has to be a 16 byte aligned address to match cache reads we're running
				m_axi.araddr <= scanaddr + scanoffset;
				m_axi.arvalid <= 1;
				scanstate <= TRIGGERBURST;
			end
			TRIGGERBURST: begin
				if (/*m_axi.arvalid && */m_axi.arready) begin
					m_axi.arvalid <= 0;
					m_axi.rready <= 1;
					scanstate <= DATABURST;
				end else begin
					scanstate <= TRIGGERBURST;
				end
			end
			DATABURST: begin
				if (m_axi.rvalid  /*&& m_axi.rready*/) begin
					// Load data into scanline cache in 128bit chunks (16 pixels at 8bpp, 20 of them)
					// TODO: video mode control should set up burst length
					scanlinecache[rdata_cnt] <= m_axi.rdata;
					rdata_cnt <= rdata_cnt + 1;
					m_axi.rready <= ~m_axi.rlast;
					scanstate <= m_axi.rlast ? DETECTSCANLINEEND : DATABURST;
				end else begin
					scanstate <= DATABURST;
				end
			end
		endcase
	end
end

endmodule
