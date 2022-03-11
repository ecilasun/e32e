`timescale 1ns / 1ps

import axi_pkg::*;

module tophat(
	// Board clock
	input wire sys_clock,
	// UART
	output wire uart_rxd_out,
	input wire uart_txd_in,
    // HID
    input wire ps2_clk,
    input wire ps2_data,
	// HDMI/DVI
	output wire [2:0] hdmi_tx_p,
	output wire [2:0] hdmi_tx_n,
	output wire hdmi_tx_clk_p,
	output wire hdmi_tx_clk_n/*,
	// DDR3
    output wire ddr3_reset_n,
    output wire [0:0] ddr3_cke,
    output wire [0:0] ddr3_ck_p,
    output wire [0:0] ddr3_ck_n,
    output wire ddr3_ras_n,
    output wire ddr3_cas_n,
    output wire ddr3_we_n,
    output wire [2:0] ddr3_ba,
    output wire [14:0] ddr3_addr,
    output wire [0:0] ddr3_odt,
    output wire [1:0] ddr3_dm,
    inout wire [1:0] ddr3_dqs_p,
    inout wire [1:0] ddr3_dqs_n,
    inout wire [15:0] ddr3_dq*/ );

// ----------------------------------------------------------------------------
// Clock / Reset generator
// ----------------------------------------------------------------------------

wire aclk, wallclock, uartbaseclock, pixelclock, videoclock, hidclock, clk_sys_i, clk_ref_i, aresetn;
clockandreset ClockAndResetGen(
	.sys_clock_i(sys_clock),
	.busclock(aclk),
	.wallclock(wallclock),
	.uartbaseclock(uartbaseclock),
	.pixelclock(pixelclock),
	.videoclock(videoclock),
	.hidclock(hidclock),
	.clk_sys_i(clk_sys_i),
	.clk_ref_i(clk_ref_i),
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
axi_if A4CH4();
axi_if A4UCH4();
axi_if A4CH5();
axi_if A4UCH5();

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

rv32cpu #(.RESETVECTOR(32'h20000000), .HARTID(4)) HART4 (
	.aclk(aclk),
	.aresetn(aresetn),
	.a4buscached(A4CH4),
	.a4busuncached(A4UCH4) );

rv32cpu #(.RESETVECTOR(32'h20000000), .HARTID(5)) HART5 (
	.aclk(aclk),
	.aresetn(aresetn),
	.a4buscached(A4CH5),
	.a4busuncached(A4UCH5) );

/*rv32cpu #(.RESETVECTOR(32'h20000000), .HARTID(6)) HART6 (
	.aclk(aclk),
	.aresetn(aresetn),
	.a4buscached(A4CH6),
	.a4busuncached(A4UCH6) );*/

// ----------------------------------------------------------------------------
// HART arbiters for cached and uncached busses
// ----------------------------------------------------------------------------

arbiter CARB(
	.aclk(aclk),
	.aresetn(aresetn),
	.M({A4CH5, A4CH4, A4CH3, A4CH2, A4CH1, A4CH0}),
	.S(A4CH) );

arbiter UCARB(
	.aclk(aclk),
	.aresetn(aresetn),
	.M({A4UCH5, A4UCH4, A4UCH3, A4UCH2, A4UCH1, A4UCH0}),
	.S(A4UCH) );

// ----------------------------------------------------------------------------
// Cached devices (unrouted for now)
// ----------------------------------------------------------------------------

gpudataoutput gpudata(
	.tmdsp(hdmi_tx_p),
	.tmdsn(hdmi_tx_n),
	.tmdsclkp(hdmi_tx_clk_p ),
	.tmdsclkn(hdmi_tx_clk_n) );

wire calib_done, ui_clk;
/*ddr3devicewires ddr3wires(
	.ddr3_reset_n(ddr3_reset_n),
	.ddr3_cke(ddr3_cke),
	.ddr3_ck_p(ddr3_ck_p), 
	.ddr3_ck_n(ddr3_ck_n),
	.ddr3_ras_n(ddr3_ras_n), 
	.ddr3_cas_n(ddr3_cas_n), 
	.ddr3_we_n(ddr3_we_n),
	.ddr3_ba(ddr3_ba),
	.ddr3_addr(ddr3_addr),
	.ddr3_odt(ddr3_odt),
	.ddr3_dm(ddr3_dm),
	.ddr3_dqs_p(ddr3_dqs_p),
	.ddr3_dqs_n(ddr3_dqs_n),
	.ddr3_dq(ddr3_dq) );*/

wire bramclk = aclk;
cacheddevicechain CDEVICECHAIN(
	.aclk(aclk),
	.bramclk(bramclk),
	.aresetn(aresetn),
	.clk_sys_i(clk_sys_i),
	.clk_ref_i(clk_ref_i),
	.calib_done(calib_done),
	.ui_clk(ui_clk),
	//.ddr3wires(ddr3wires),
	.axi4if(A4CH) );

// ----------------------------------------------------------------------------
// Uncached device router
// ----------------------------------------------------------------------------

uncacheddevicechain UCDEVICECHAIN(
	.aclk(aclk),
	.pixelclock(pixelclock),
	.videoclock(videoclock),
	.uartbaseclock(uartbaseclock),
	.hidclock(hidclock),
	.aresetn(aresetn),
	.uart_rxd_out(uart_rxd_out),
	.uart_txd_in(uart_txd_in),
    .ps2_clk(ps2_clk),
    .ps2_data(ps2_data),
	.axi4if(A4UCH),
	.gpudata(gpudata),
	.irq(irq) );

endmodule
