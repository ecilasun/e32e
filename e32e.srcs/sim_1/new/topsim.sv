`timescale 1ns / 1ps

module topsim( );

wire uart_txd_in = 1'b1;
//wire uart_rxd_out;

logic board_clock = 0;
always #5 board_clock = ~board_clock;

tophat tophatsiminst(
	.sys_clock(board_clock),
	.uart_rxd_out(/*uart_rxd_out*/),
	.uart_txd_in(uart_txd_in) );

endmodule
