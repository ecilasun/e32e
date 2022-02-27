`timescale 1ns / 1ps

module uartcontroller(
	input wire uartclk,
	input wire aclk,
	input wire aresetn,
	// Write
	input wire [31:0] outfifoin,
	input wire outfifowe,
	output logic writedone,
	// Read
	output wire [31:0] infifoout,
	input wire infifore,
	output logic readdone,
	// UART wires
	output wire uart_rxd_out,
	input wire uart_txd_in );

// Transmitter (CPU -> FIFO -> Tx)

always @(posedge aclk) begin
	if (~aresetn) begin
		readdone <= 1'b0;
		writedone <= 1'b0;
	end else begin
		// Simple delay for one clock as all read/writes complete in one cycle
		// However, this doesn't take any fifo full/empty into account (just for test)
		readdone <= infifore;
		writedone <= outfifowe;
	end
end

wire [7:0] outfifoout;
wire outfifofull, uarttxbusy, outfifoempty, outfifovalid;
logic [7:0] datatotransmit = 8'h00;
logic transmitbyte = 1'b0;
logic txstate = 1'b0;
logic outfifore = 1'b0;

async_transmitter UART_transmit(
	.clk(uartclk),
	.txd_start(transmitbyte),
	.txd_data(datatotransmit),
	.txd(uart_rxd_out),
	.txd_busy(uarttxbusy) );

// Output FIFO
uartoutfifo UART_out_fifo(
    // In
    .full(outfifofull),
    .din(outfifoin[7:0]),	// Data latched from CPU
    .wr_en(outfifowe),		// CPU controls write, high for one clock
    // Out
    .empty(outfifoempty),	// Nothing to read
    .dout(outfifoout),		// To transmitter
    .rd_en(outfifore),		// Transmitter can send
    .wr_clk(aclk),			// CPU write clock
    .rd_clk(uartclk),		// Transmitter clock runs much slower
    .valid(outfifovalid),	// Read result valid
    // Ctl
    .rst(~aresetn) );

// Fifo output serializer
always @(posedge uartclk) begin
	if (txstate == 1'b0) begin // IDLE_STATE
		if (~uarttxbusy & (transmitbyte == 1'b0)) begin // Safe to attempt send, UART not busy or triggered
			if (~outfifoempty) begin // Something in FIFO? Trigger read and go to transmit 
				outfifore <= 1'b1;			
				txstate <= 1'b1;
			end else begin
				outfifore <= 1'b0;
				txstate <= 1'b0; // Stay in idle state
			end
		end else begin // Transmit hardware busy or we kicked a transmit (should end next clock)
			outfifore <= 1'b0;
			txstate <= 1'b0; // Stay in idle state
		end
		transmitbyte <= 1'b0;
	end else begin // TRANSMIT_STATE
		outfifore <= 1'b0; // Stop read request
		if (outfifovalid) begin // Kick send and go to idle
			datatotransmit <= outfifoout;
			transmitbyte <= 1'b1;
			txstate <= 1'b0;
		end else begin
			txstate <= 1'b1; // Stay in transmit state and wait for valid fifo data
		end
	end
end

// Receiver (Rx -> FIFO -> CPU)

wire [7:0] uartbytein, uartincoming;
wire infifoempty, infifoe, infifovalid, uartbyteavailable;
logic [7:0] inuartbyte;
logic infifowe = 1'b0;

async_receiver UART_receive(
	.clk(uartclk),
	.rxd(uart_txd_in),
	.rxd_data_ready(uartbyteavailable),
	.rxd_data(uartbytein),
	.rxd_idle(),
	.rxd_endofpacket() );

// Input FIFO
uartinfifo UART_in_fifo(
    // In
    .full(),
    .din(inuartbyte),
    .wr_en(infifowe),
    // Out
    .empty(infifoempty),
    .dout(uartincoming),
    .rd_en(infifore),
    .wr_clk(uartclk),
    .rd_clk(aclk),
    .valid(infifovalid),
    // Ctl
    .rst(~aresetn) );

assign infifoout = {24'd0, uartincoming};

// Fifo input control
always @(posedge uartclk) begin
	if (uartbyteavailable) begin
		infifowe <= 1'b1;
		inuartbyte <= uartbytein;
	end else begin
		infifowe <= 1'b0;
	end
end

endmodule
