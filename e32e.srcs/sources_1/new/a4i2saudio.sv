`timescale 1ns / 1ps

module a4i2saudio (
	input wire aclk,
	input wire aresetn,
    input wire hidclock,		// 50MHz clock shared with PS/2
    axi_if.slave s_axi,
    inout scl,					// I2C SCL for audio chip
    inout sda,					// I2C SDA for audio chip
    output wire ac_bclk,		// Audio bus
    output wire ac_lrclk,		// L/R sample clock
    output wire ac_dac_sdata,	// DAC output (i.e. playback)
    input wire ac_adc_sdata );	// ADC input is set up but not used yet

// TODO: Allow sample rate and volume control from CPU side
// TODO: Tie to memory bus instead of internal FIFO (same as GPU, scan out at own pace)
// TODO: Experiment with ADSR with wave generator or audio samples as input
// TODO: Make the above multi-channel

// ------------------------------------------------------------------------------------
// Audio Init
// ------------------------------------------------------------------------------------

wire initDone;		// I2C initialization is done
audio_init AudioI2CInit(
    .clk(hidclock),
    .rst(~aresetn),
    .sda(sda),
    .scl(scl),
    .initDone(initDone) );

// ------------------------------------------------------------------------------------
// Audio buffer
// ------------------------------------------------------------------------------------

wire abfull, abempty, abvalid;
logic [31:0] abdin = 0; // left/right channels (16 bits each)
logic abre = 1'b0;
logic abwe = 1'b0;
wire [31:0] abdout;

audiofifo AudioBuffer(
	.clk(aclk),
	.full(abfull),
	.din(abdin),
	.wr_en(abwe),
	.empty(abempty),
	.dout(abdout),
	.rd_en(abre),
	.valid(abvalid),
	.rst(~aresetn) );

// ------------------------------------------------------------------------------------
// I2S Controller
// ------------------------------------------------------------------------------------

// 16 bit output data per channel
logic [15:0] leftchannel = 0;
logic [15:0] rightchannel = 0;

i2s_ctl I2SController(
	.CLK_I(aclk),
	.RST_I((~aresetn) | (~initDone)), // Hold until I2C initialization is done
	.EN_TX_I(1'b1),
	.EN_RX_I(1'b0),
	.FS_I(4'b0101), 
	// .MM_I(1'b0),
	.D_L_I(leftchannel),
	.D_R_I(rightchannel),
	.D_L_O(),
	.D_R_O(),
	.BCLK_O(ac_bclk),
	.LRCLK_O(ac_lrclk),
	.SDATA_O(ac_dac_sdata),
	.SDATA_I(ac_adc_sdata) );

logic lrclkD1 = 0;
logic lrclkD2 = 0;
logic [3:0] lrclkcnt = 4'h0;

always@(posedge aclk) begin
	// Edge detector
	lrclkD1 <= ac_lrclk;
	lrclkD2 <= lrclkD1;

	// Stop pending reads from last clock
	abre <= 1'b0;

	// Load next sample
	if (lrclkcnt==8 && (~abempty) && abvalid)begin
		// TODO: If APU has its own burst read bus (as with GPU)
		// it can essentially use RAM instead of FIFO
		// That allows for playback by simply setting up a read
		// pointer, and sample length.
		leftchannel <= abdout[31:16];
		rightchannel <= abdout[15:0]; 
		// Advance FIFO
		abre <= 1'b1;
		lrclkcnt <= 0;
	end

	// ac_lrclk trigger high
	if (lrclkD1 & (~lrclkD2))
		lrclkcnt <= lrclkcnt + 4'd1;
end

// ------------------------------------------------------------------------------------
// Main state machine
// ------------------------------------------------------------------------------------

logic [1:0] waddrstate = 2'b00;
logic [1:0] writestate = 2'b00;
logic [1:0] raddrstate = 2'b00;

always @(posedge aclk) begin
	if (~aresetn) begin
		s_axi.awready <= 1'b0;
	end else begin
		// write address
		case (waddrstate)
			2'b00: begin
				if (s_axi.awvalid) begin
					s_axi.awready <= 1'b1;
					// TODO: Might want volume control or other effects at different s_axi.awaddr here
					waddrstate <= 2'b01;
				end
			end
			default/*2'b01*/: begin
				s_axi.awready <= 1'b0;
				waddrstate <= 2'b00;
			end
		endcase
	end
end

always @(posedge aclk) begin
	if (~aresetn) begin
		s_axi.bresp <= 2'b00; // okay
		s_axi.bvalid <= 1'b0;
		s_axi.wready <= 1'b0;
	end else begin
		// write data
		abwe <= 1'b0;
		s_axi.wready <= 1'b0;
		s_axi.bvalid <= 1'b0;
		case (writestate)
			2'b00: begin
				if (s_axi.wvalid && (~abfull)) begin
					abdin <= s_axi.wdata[31:0];
					abwe <= 1'b1;
					writestate <= 2'b01;
					s_axi.wready <= 1'b1;
				end
			end
			default/*2'b01*/: begin
				if (s_axi.bready) begin
					s_axi.bvalid <= 1'b1;
					writestate <= 2'b00;
				end
			end
		endcase
	end
end

// Can't read from the APU just yet
assign s_axi.rlast = 1'b1;
assign s_axi.arready = 1'b1;
assign s_axi.rvalid = 1'b1;
assign s_axi.rresp = 2'b00;

endmodule
