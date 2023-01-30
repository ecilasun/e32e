`timescale 1ns / 1ps

module axi4ps2keyboard(
	input wire aclk,
	input wire aresetn,
	input wire hidclock,
	input wire ps2_clk,
	input wire ps2_data,
	axi_if.slave s_axi,
	output wire ps2fifoempty );

wire [15:0] scan_code;
wire scan_code_ready;
logic read_n = 1'b1;

ps2_keyboard ps2receiverinstance(
    .clk(hidclock),
    .clrn(aresetn),
    .ps2_clk(ps2_clk),
    .ps2_data(ps2_data),
    .rdn(read_n),
    .data(scan_code),
    .ready(scan_code_ready),
    .overflow());

logic [1:0] raddrstate = 2'b00;

wire fifofull, fifovalid;
logic fifowe = 1'b0, fifore = 1'b0;
logic [15:0] fifodin = 16'd0;
wire [15:0] fifodout;

ps2infifo ps2inputfifo(
	.wr_clk(hidclock),
	.full(fifofull),
	.din(fifodin),
	.wr_en(fifowe),

	.rd_clk(aclk),
	.empty(ps2fifoempty),
	.dout(fifodout),
	.rd_en(fifore),
	.valid(fifovalid),

	.rst(~aresetn) );

logic keyreadstate = 1'b0;
always @(posedge hidclock) begin
	if (~aresetn) begin
		//
	end else begin
		fifowe <= 1'b0;
		read_n <= 1'b1;

		case (keyreadstate)
			1'b0: begin
				if (scan_code_ready & (~fifofull)) begin // make sure to drain the fifo!
					keyreadstate <= 1'b1;
					read_n <= 1'b0;
				end
			end
			1'b1: begin
				// stash incoming byte in fifo
				fifowe <= 1'b1;
				fifodin <= scan_code;
				keyreadstate <= 1'b0;
			end
		endcase
	end
end

// ----------------------------------------------------------------------------
// main state machine
// ----------------------------------------------------------------------------

always @(posedge aclk) begin
	if (~aresetn) begin
		s_axi.awready <= 1'b1;
	end else begin
		// Completely ignore writes and always return success
		s_axi.awready <= 1'b1;
		s_axi.wready <= 1'b1;
		s_axi.bvalid <= 1'b1;
		s_axi.bresp = 2'b00; // okay
	end
end

always @(posedge aclk) begin
	if (~aresetn) begin
		s_axi.rlast <= 1'b1;
		s_axi.arready <= 1'b0;
		s_axi.rvalid <= 1'b0;
		s_axi.rresp <= 2'b00;
	end else begin

		fifore <= 1'b0;
		s_axi.arready <= 1'b0;
		s_axi.rvalid <= 1'b0;

		case (raddrstate)
			2'b00: begin
				if (s_axi.arvalid) begin
					s_axi.arready <= 1'b1;
					raddrstate <= 2'b01;
				end
			end
			2'b01: begin
				if (s_axi.rready) begin
					if (s_axi.araddr[3:0] == 4'h4) begin // incoming data available?
						s_axi.rdata[31:0] <= {31'd0, ~ps2fifoempty};
						s_axi.rvalid <= 1'b1;
						raddrstate <= 2'b11;
					end else if (~ps2fifoempty) begin
						fifore <= 1'b1;
						raddrstate <= 2'b10;
					end
				end
			end
			2'b10: begin
				if (fifovalid) begin
					s_axi.rdata[31:0] <= {16'd0, fifodout}; // key scan code
					s_axi.rvalid <= 1'b1;
					raddrstate <= 2'b11;
				end
			end
			default/*2'b11*/: begin
				raddrstate <= 2'b00;
			end
		endcase
	end
end

endmodule
