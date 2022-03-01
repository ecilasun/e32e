`timescale 1ns / 1ps

import axi_pkg::*;

module tophat(
	input wire sys_clock,
	output wire uart_rxd_out,
	input wire uart_txd_in );

// ----------------------------------------------------------------------------
// Clock / Reset generator
// ----------------------------------------------------------------------------

wire aclk, wallclock, uartbaseclock, aresetn;
clockandreset ClockAndResetGen(
	.sys_clock_i(sys_clock),
	.busclock(aclk),
	.wallclock(wallclock),
	.uartbaseclock(uartbaseclock),
	//.pixelclock(pixelclock),
	//.videoclock(videoclock),
	//.clk_sys_i(clk_sys_i),
	//.clk_ref_i(clk_ref_i),
	.selfresetn(aresetn) );

// ----------------------------------------------------------------------------
// Cached / Uncached AXI connections
// ----------------------------------------------------------------------------

axi_if A4CH0();
axi_if A4UCH0();

axi_if brambus();

// ----------------------------------------------------------------------------
// HARTs
// ----------------------------------------------------------------------------

rv32cpu #(.RESETVECTOR(32'h80000000), .HARTID(0)) HART0 (
	.aclk(aclk),
	.aresetn(aresetn),
	.a4buscached(A4CH0),
	.a4busuncached(A4UCH0) );

// ----------------------------------------------------------------------------
// Cached devices
// ----------------------------------------------------------------------------

// TODO: AXI crossbar here to reduce all A4CH* to one A4UCH bus

a4bram BRAM64(
	.aclk(aclk),
	.aresetn(aresetn),
	.s_axi(A4CH0) );

// ----------------------------------------------------------------------------
// Uncached devices
// ----------------------------------------------------------------------------

// TODO: AXI crossbar here to reduce all A4UCH* to one A4UCH bus

wire uartrcvempty; // TODO: to drive interrupts with
axi4uart UART(
	.aclk(aclk),
	.aresetn(aresetn),
	.s_axi(A4UCH0),
	.uartbaseclock(uartbaseclock),
	.uart_rxd_out(uart_rxd_out),
	.uart_txd_in(uart_txd_in),
	.uartrcvempty(uartrcvempty) );

endmodule
