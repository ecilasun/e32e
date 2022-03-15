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
	output wire hdmi_tx_clk_n,
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
    inout wire [15:0] ddr3_dq );

// ----------------------------------------------------------------------------
// Device address map
// ----------------------------------------------------------------------------

// Address space is arranged so that device addresses below 0x80000000 are cached
// DDR3: 00000000..20000000 : [ ] cached r/w
// BRAM: 20000000..2000FFFF : [+] cached r/w
// ... : 20010000..7FFFFFFF : [-] unused
// MAIL: 80000000..80000FFF : [+] uncached r/w
// UART: 80001000..8000100F : [+] uncached r/w
//  SPI: 80001010..8000101F : [ ] uncached r/w
// PS/2: 80001020..8000102F : [ ] uncached r/w
//  BTN: 80001030..8000103F : [ ] uncached r/w
//  LED: 80001040..8000104F : [ ] uncached r/w
// ... : 80001050..80FFFFFF : [-] unused
//  FB0: 81000000..8101FFFF : [+] uncached w
//  FB1: 81020000..8103FFFF : [ ] uncached w
//  PAL: 81040000..810400FF : [+] uncached w
//  GPU: 81040100..8104FFFF : [ ] uncached w
// ... : 81050000..FFFFFFFF : [-] unused

// ----------------------------------------------------------------------------
// Clock / Reset generator
// ----------------------------------------------------------------------------

wire calib_done;
wire aclk, wallclock, uartbaseclock, pixelclock, videoclock, hidclock, clk_sys_i, clk_ref_i, aresetn;
clockandreset ClockAndResetGen(
	.calib_done(calib_done),
	.sys_clock_i(sys_clock),
	.busclock(aclk),
	.wallclock(wallclock),
	.uartbaseclock(uartbaseclock),
	.pixelclock(pixelclock),
	.videoclock(videoclock),
	.hidclock(hidclock),
	.clk_sys_i(clk_sys_i),
	.clk_ref_i(clk_ref_i),
	.selfresetn(selfresetn),
	.aresetn(aresetn) );

// ----------------------------------------------------------------------------
// Wallclock for timeh/l CSR
// ----------------------------------------------------------------------------
logic [63:0] wallclocktime = 'd0;
logic [63:0] cpuclocktime = 'd0;
always_ff @(posedge wallclock) begin
	wallclocktime <= wallclocktime + 1;
end
always_ff @(posedge aclk) begin
	cpuclocktime <= cpuclocktime + 1;
end

// ----------------------------------------------------------------------------
// Cached / Uncached AXI connections
// ----------------------------------------------------------------------------

axi_if A4CH0(), A4UCH0();
axi_if A4CH1(), A4UCH1();
axi_if A4CH2(), A4UCH2();
axi_if A4CH3(), A4UCH3();
axi_if A4CH4(), A4UCH4();
axi_if A4CH5(), A4UCH5();
axi_if A4CH6(), A4UCH6();
axi_if A4CH7(), A4UCH7();

axi_if A4CH(), A4UCH();

wire [3:0] irq;

// ----------------------------------------------------------------------------
// HARTs
// ----------------------------------------------------------------------------

rv32cpu #(.RESETVECTOR(32'h20000000), .HARTID(0)) HART0 (
	.aclk(aclk),
	.wallclocktime(wallclocktime),
	.cpuclocktime(cpuclocktime),
	.aresetn(aresetn),
	.a4buscached(A4CH0),
	.a4busuncached(A4UCH0) );

rv32cpu #(.RESETVECTOR(32'h20000000), .HARTID(1)) HART1 (
	.aclk(aclk),
	.wallclocktime(wallclocktime),
	.cpuclocktime(cpuclocktime),
	.aresetn(aresetn),
	.a4buscached(A4CH1),
	.a4busuncached(A4UCH1) );

rv32cpu #(.RESETVECTOR(32'h20000000), .HARTID(2)) HART2 (
	.aclk(aclk),
	.wallclocktime(wallclocktime),
	.cpuclocktime(cpuclocktime),
	.aresetn(aresetn),
	.a4buscached(A4CH2),
	.a4busuncached(A4UCH2) );

rv32cpu #(.RESETVECTOR(32'h20000000), .HARTID(3)) HART3 (
	.aclk(aclk),
	.wallclocktime(wallclocktime),
	.cpuclocktime(cpuclocktime),
	.aresetn(aresetn),
	.a4buscached(A4CH3),
	.a4busuncached(A4UCH3) );

rv32cpu #(.RESETVECTOR(32'h20000000), .HARTID(4)) HART4 (
	.aclk(aclk),
	.wallclocktime(wallclocktime),
	.cpuclocktime(cpuclocktime),
	.aresetn(aresetn),
	.a4buscached(A4CH4),
	.a4busuncached(A4UCH4) );

rv32cpu #(.RESETVECTOR(32'h20000000), .HARTID(5)) HART5 (
	.aclk(aclk),
	.wallclocktime(wallclocktime),
	.cpuclocktime(cpuclocktime),
	.aresetn(aresetn),
	.a4buscached(A4CH5),
	.a4busuncached(A4UCH5) );

rv32cpu #(.RESETVECTOR(32'h20000000), .HARTID(6)) HART6 (
	.aclk(aclk),
	.wallclocktime(wallclocktime),
	.cpuclocktime(cpuclocktime),
	.aresetn(aresetn),
	.a4buscached(A4CH6),
	.a4busuncached(A4UCH6) );

rv32cpu #(.RESETVECTOR(32'h20000000), .HARTID(7)) HART7 (
	.aclk(aclk),
	.wallclocktime(wallclocktime),
	.cpuclocktime(cpuclocktime),
	.aresetn(aresetn),
	.a4buscached(A4CH7),
	.a4busuncached(A4UCH7) );

// ----------------------------------------------------------------------------
// HART arbiters for cached and uncached busses
// ----------------------------------------------------------------------------

arbiter CARB(
	.aclk(aclk),
	.aresetn(aresetn),
	.M({A4CH7, A4CH6, A4CH5, A4CH4, A4CH3, A4CH2, A4CH1, A4CH0}),
	.S(A4CH) );

arbiter UCARB(
	.aclk(aclk),
	.aresetn(aresetn),
	.M({A4UCH7, A4UCH6, A4UCH5, A4UCH4, A4UCH3, A4UCH2, A4UCH1, A4UCH0}),
	.S(A4UCH) );

// ----------------------------------------------------------------------------
// Cached devices (unrouted for now)
// ----------------------------------------------------------------------------

gpudataoutput gpudata(
	.tmdsp(hdmi_tx_p),
	.tmdsn(hdmi_tx_n),
	.tmdsclkp(hdmi_tx_clk_p ),
	.tmdsclkn(hdmi_tx_clk_n) );

ddr3devicewires ddr3wires(
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
	.ddr3_dq(ddr3_dq) );

cacheddevicechain CDEVICECHAIN(
	.aclk(aclk),
	.aresetn(aresetn),
	.selfresetn(selfresetn), // FOR DDR3
	.clk_sys_i(clk_sys_i),
	.clk_ref_i(clk_ref_i),
	.calib_done(calib_done),
	.ddr3wires(ddr3wires),
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
