`timescale 1ns / 1ps

module a4i2saudio (
	input wire aclk,
	input wire aresetn,
    input wire hidclock,		// 50MHz clock
    axi_if.slave s_axi,
    inout scl,					// I2C bus
    inout sda,
    output wire initDone,
    output wire ac_bclk,
    output wire ac_lrclk,
    output wire ac_dac_sdata,
    input wire ac_adc_sdata );

// ------------------------------------------------------------------------------------
// Audio Init
// ------------------------------------------------------------------------------------

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

logic [15:0] leftchannel = 0;
logic [15:0] rightchannel = 0;

i2s_ctl I2SController(
.CLK_I(aclk),
.RST_I(~aresetn),		 
.EN_TX_I(1'b1),
.EN_RX_I(1'b0),
.FS_I(4'b0101), 
.MM_I(1'b0),
.D_L_I({leftchannel, 8'd0}),
.D_R_I({rightchannel, 8'd0}),
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
	lrclkD1 <= ac_lrclk;
	lrclkD2 <= lrclkD1;
	abre <= 1'b0;

	if (lrclkcnt==8 && (~abempty))begin
		abre <= 1'b1;
		lrclkcnt<=0;
	end

	if (lrclkD1 & (~lrclkD2))
		lrclkcnt <= lrclkcnt + 4'd1;

	if (abvalid) begin
		leftchannel <= abdout[31:16];
		rightchannel <= abdout[15:0]; 
	end
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
					//writeaddress <= s_axi.awaddr; // todo: select subdevice using some bits of address
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
				// cannot read this, return zero
				s_axi.rdata[31:0] <= 32'd0;
				s_axi.rvalid <= 1'b1;
				raddrstate <= 2'b00;
			end
		endcase
	end
end

endmodule
