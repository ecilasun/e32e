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
    inout wire [15:0] ddr3_dq,
    // SPI
	output wire spi_cs_n,
	output wire spi_mosi,
	input wire spi_miso,
	output wire spi_sck,
	input wire spi_cd,
	output wire sd_poweron_n,
	// I2C bus
    inout scl,
    inout sda,
	// I2S
    output wire ac_mclk,		// 12MHz clock fed into the audio chip
    input wire ac_adc_sdata,
    output wire ac_dac_sdata,
    output wire ac_bclk,
    output wire ac_lrclk,
    // Debug LEDs
    output wire [7:0] led );

// ----------------------------------------------------------------------------
// External device connections
// ----------------------------------------------------------------------------

// Always grounded to keep sdcard powered
// TODO: Should be software controlled
assign sd_poweron_n = 1'b0;

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

devicewires wires(
	.uart_rxd_out(uart_rxd_out),
	.uart_txd_in(uart_txd_in),
	.ps2_clk(ps2_clk),
	.ps2_data(ps2_data),
	.spi_cs_n(spi_cs_n),
	.spi_mosi(spi_mosi),
	.spi_miso(spi_miso),
	.spi_sck(spi_sck),
	.spi_cd(spi_cd),
	.scl(scl),
	.sda(sda),
	.ac_bclk(ac_bclk),
	.ac_lrclk(ac_lrclk),
	.ac_dac_sdata(ac_dac_sdata),
	.ac_adc_sdata(ac_adc_sdata),
	.led(led) );

gpudataoutput gpudata(
	.tmdsp(hdmi_tx_p),
	.tmdsn(hdmi_tx_n),
	.tmdsclkp(hdmi_tx_clk_p ),
	.tmdsclkn(hdmi_tx_clk_n) );

// ----------------------------------------------------------------------------
// Device address map
// ----------------------------------------------------------------------------

// Address space is arranged so that device
// addresses below 0x80000000 are cached
//    DDR3: 00000000..1FFFFFFF : [+] cached r/w
//    BRAM: 20000000..2000FFFF : [+] cached r/w
//   ...  : 20010000..7FFFFFFF : [ ] unused
//    MAIL: 80000000..80000FFF : [+] uncached r/w
//    UART: 80001000..8000100F : [+] uncached r/w
//     SPI: 80001010..8000101F : [+] uncached r/w
//    PS/2: 80001020..8000102F : [+] uncached r/w
//     LED: 80001030..8000103F : [ ] uncached r/w
//    HART: 80001040..8000104F : [ ] uncached w
//  GPUCMD: 81001050..8100105F : [ ] uncached w
//   ...  : 80001060..81FFFFFF : [ ] unused
//     APU: 82000000..8200000F : [+] uncached w
//   ...  : 82000010..FFFFFFFF : [ ] unused

// ----------------------------------------------------------------------------
// Clock / Reset generator
// ----------------------------------------------------------------------------

wire calib_done;				// High when DDR3 calibration completes (which in turn allows for reset to be released)
wire aclk;						// Core system / bus clock. CPUs also run at this rate.
wire wallclock;					// Wall clock to be used in realtime clock measurements in software
wire uartbaseclock;				// UART core clock (20MHz at this moment)
wire spibaseclock;				// SPI Master core clock (50MHz at this moment giving a speed of 12.5MHz SDCard access)
wire pixelclock, videoclock;	// Video pixel clock (25MHz) and the video clock for DVI shifter (250MHz)
wire hidclock;					// Clock shared between PS/2 device and audio I2C initialization device (50MHz)
wire clk_sys_i, clk_ref_i;		// DDR3 clocks (100MHz system clock and a 200MHz reference clock)
wire aresetn;					// Auto-generated system-wide reset signal

clockandreset ClockAndResetGen(
	.calib_done(calib_done),
	.sys_clock_i(sys_clock),
	.busclock(aclk),
	.wallclock(wallclock),
	.uartbaseclock(uartbaseclock),
	.spibaseclock(spibaseclock),
	.pixelclock(pixelclock),
	.videoclock(videoclock),
	.hidclock(hidclock),
	.clk_sys_i(clk_sys_i),
	.clk_ref_i(clk_ref_i),
	.audioclock(ac_mclk),
	.selfresetn(selfresetn),
	.aresetn(aresetn) );

// ----------------------------------------------------------------------------
// Wallclock for timeh/l CSR
// ----------------------------------------------------------------------------

// These counters are fed into each core and are mapped to CSR space
// Reading corresponding CSRs will return these values.
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

// Wires between each core and their cached/uncached bus i/o
axi_if A4CH0(), A4UCH0();
axi_if A4CH1(), A4UCH1();
axi_if A4CH2(), A4UCH2();

// Arbitrated cached and uncached busses
axi_if A4CH(), A4UCH();

// IRQs in descending bit order
//  11 10 9  8  7   6  5  4  3      2   1      0
// [-- -- -- -- GPU H2 H1 H0 unused PS2 unused UART]
wire [11:0] irq;

// ----------------------------------------------------------------------------
// RISC-V HARTs
// NOTE: They all boot from the same reset vector at the moment.
// Software handles HARTID detection and takes the correct action,
// while also setting up stack pointers at startup.
// This means only HART0 does the full CRT runtime initialization,
// while the others boot up in WFI mode, inside an infinite loop
// waiting to be woken up.
// Currently the ROM image can detect up to 16 HARTs.
// Ideal count recommended is two (HART#0 and HART#1) for most scenarios.
// Simply comment out the HARTS starting from the last one to fit your needs.
// Only the first HART contains an FPU, the remaining HARTs are planned to
// contain a specific set of custom instructions and are kept smaller.
// ----------------------------------------------------------------------------

rv32cpu #(.RESETVECTOR(32'h20000000), .HARTID(0)) HART0 (
	.aclk(aclk),
	.wc0(wallclocktime),
	.cc0(cpuclocktime),
	.aresetn(aresetn),
	.irq({irq[4], irq[3:0]}),	// H0 unused PS2 unused UART
	.a4buscached(A4CH0),
	.a4busuncached(A4UCH0) );

rv32cpunofpu #(.RESETVECTOR(32'h20000000), .HARTID(1)) HART1 (
	.aclk(aclk),
	.wc0(wallclocktime),
	.cc0(cpuclocktime),
	.aresetn(aresetn),
	.irq({irq[5], irq[3:0]}),	// H1 unused PS2 unused UART
	.a4buscached(A4CH1),
	.a4busuncached(A4UCH1) );

rv32cpunofpu #(.RESETVECTOR(32'h20000000), .HARTID(2)) HART2 (
	.aclk(aclk),
	.wc0(wallclocktime),
	.cc0(cpuclocktime),
	.aresetn(aresetn),
	.irq({irq[6], irq[3:0]}),	// H2 unused PS2 unused UART
	.a4buscached(A4CH2),
	.a4busuncached(A4UCH2) );

// GPU + SCANOUT
axi_if gpubus();
wire gpufifoempty;
wire [31:0] gpufifodout;
wire gpufifore;
wire gpufifovalid;
gpu gpuinst(
	.aclk(aclk),
	.clk25(pixelclock),
	.clk250(videoclock),
	.aresetn(aresetn),
	.m_axi(gpubus),
	.gpudata(gpudata),
	.gpufifoempty(gpufifoempty),
	.gpufifodout(gpufifodout),
	.gpufifore(gpufifore),
	.gpufifovalid(gpufifovalid) );

// ----------------------------------------------------------------------------
// HART arbiters for cached and uncached busses
// ----------------------------------------------------------------------------

// Cached bus arbiter
arbiter CARB(
	.aclk(aclk),
	.aresetn(aresetn),
	.axi_s({gpubus, A4CH2, A4CH1, A4CH0}),
	.axi_m(A4CH) );

// Uncached bus arbiter
ucarbiter UCARB(
	.aclk(aclk),
	.aresetn(aresetn),
	.axi_s({A4UCH2, A4UCH1, A4UCH0}),
	.axi_m(A4UCH) );

// ----------------------------------------------------------------------------
// Cached devices (unrouted for now)
// ----------------------------------------------------------------------------

// Cached devices and wires
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

// Uncached devices and wires
uncacheddevicechain UCDEVICECHAIN(
	// Clocks
	.aclk(aclk),
	.pixelclock(pixelclock),
	.videoclock(videoclock),
	.uartbaseclock(uartbaseclock),
	.spibaseclock(spibaseclock),
	.hidclock(hidclock),
	// Bus/IRQ/Init
	.aresetn(aresetn),
	.axi4if(A4UCH),
	.irq(irq),
	// GPU
	.gpufifoempty(gpufifoempty),
	.gpufifodout(gpufifodout),
	.gpufifore(gpufifore),
	.gpufifovalid(gpufifovalid),
	// Device wires
	.wires(wires) );

endmodule
