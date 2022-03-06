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
axi_if A4CH1();
axi_if A4UCH1();

axi_if A4CH();
axi_if A4UCH();

wire [3:0] irq;

// ----------------------------------------------------------------------------
// HARTs
// ----------------------------------------------------------------------------

rv32cpu #(.RESETVECTOR(32'h20000000), .HARTID(0)) HART0 (
	.aclk(aclk),
	.aresetn(aresetn),
	.a4buscached(A4CH0),
	.a4busuncached(A4UCH0) );

rv32cpu #(.RESETVECTOR(32'h20000000), .HARTID(1)) HART1 (
	.aclk(aclk),
	.aresetn(aresetn),
	.a4buscached(A4CH1),
	.a4busuncached(A4UCH1) );

// ----------------------------------------------------------------------------
// HART arbiters for cached and uncached busses
// ----------------------------------------------------------------------------

arbiter ARBCACHED(
	.aclk(aclk),
	.aresetn(aresetn),
	.M({A4CH1, A4CH0}),
	.S(A4CH) );

arbiter ARBUNCACHED(
	.aclk(aclk),
	.aresetn(aresetn),
	.M({A4UCH1, A4UCH0}),
	.S(A4UCH) );

// ----------------------------------------------------------------------------
// Cached devices (unrouted for now)
// ----------------------------------------------------------------------------

cacheddevicechain CDEVICECHAIN(
	.aclk(aclk),
	.aresetn(aresetn),
	.axi4if(A4CH) );

// ----------------------------------------------------------------------------
// Uncached device router
// ----------------------------------------------------------------------------

uncacheddevicechain UCDEVICECHAIN(
	.aclk(aclk),
	.aresetn(aresetn),
	.uartbaseclock(uartbaseclock),
	.uart_rxd_out(uart_rxd_out),
	.uart_txd_in(uart_txd_in),
	.axi4if(A4UCH),
	.irq(irq) );

endmodule
