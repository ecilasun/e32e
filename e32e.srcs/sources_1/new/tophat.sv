`timescale 1ns / 1ps

import axi_pkg::*;

module tophat(
	// Board clock
	input wire sys_clock,
	// UART
	output wire uart_rxd_out,
	input wire uart_txd_in,
	// HDMI/DVI
	output wire [2:0] hdmi_tx_p,
	output wire [2:0] hdmi_tx_n,
	output wire hdmi_tx_clk_p,
	output wire hdmi_tx_clk_n );

// ----------------------------------------------------------------------------
// Clock / Reset generator
// ----------------------------------------------------------------------------

wire aclk, wallclock, uartbaseclock, pixelclock, videoclock, aresetn;
clockandreset ClockAndResetGen(
	.sys_clock_i(sys_clock),
	.busclock(aclk),
	.wallclock(wallclock),
	.uartbaseclock(uartbaseclock),
	.pixelclock(pixelclock),
	.videoclock(videoclock),
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
axi_if A4CH2();
axi_if A4UCH2();
axi_if A4CH3();
axi_if A4UCH3();

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

rv32cpu #(.RESETVECTOR(32'h20000000), .HARTID(2)) HART2 (
	.aclk(aclk),
	.aresetn(aresetn),
	.a4buscached(A4CH2),
	.a4busuncached(A4UCH2) );

rv32cpu #(.RESETVECTOR(32'h20000000), .HARTID(3)) HART3 (
	.aclk(aclk),
	.aresetn(aresetn),
	.a4buscached(A4CH3),
	.a4busuncached(A4UCH3) );

// ----------------------------------------------------------------------------
// HART arbiters for cached and uncached busses
// ----------------------------------------------------------------------------

arbiter CARB(
	.aclk(aclk),
	.aresetn(aresetn),
	.M({A4CH3, A4CH2, A4CH1, A4CH0}),
	.S(A4CH) );

arbiter UCARB(
	.aclk(aclk),
	.aresetn(aresetn),
	.M({A4UCH3, A4UCH2, A4UCH1, A4UCH0}),
	.S(A4UCH) );

// ----------------------------------------------------------------------------
// Cached devices (unrouted for now)
// ----------------------------------------------------------------------------

gpudataoutput gpudata(
	.tmdsp(hdmi_tx_p),
	.tmdsn(hdmi_tx_n),
	.tmdsclkp(hdmi_tx_clk_p ),
	.tmdsclkn(hdmi_tx_clk_n) );

cacheddevicechain CDEVICECHAIN(
	.aclk(aclk),
	.aresetn(aresetn),
	.axi4if(A4CH) );

// ----------------------------------------------------------------------------
// Uncached device router
// ----------------------------------------------------------------------------

uncacheddevicechain UCDEVICECHAIN(
	.aclk(aclk),
	.pixelclock(pixelclock),
	.videoclock(videoclock),
	.uartbaseclock(uartbaseclock),
	.aresetn(aresetn),
	.uart_rxd_out(uart_rxd_out),
	.uart_txd_in(uart_txd_in),
	.axi4if(A4UCH),
	.gpudata(gpudata),
	.irq(irq) );

endmodule
