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

// One pair per HART
axi_if A4CH0();
axi_if A4UCH0();
//axi_if A4CH1();
//axi_if A4UCH1();

// One per device
axi_if brambus();

// ----------------------------------------------------------------------------
// HARTs
// ----------------------------------------------------------------------------

rv32cpu #(.RESETVECTOR(32'h80000000), .HARTID(0)) HART0 (
	.aclk(aclk),
	.aresetn(aresetn),
	.a4buscached(A4CH0),
	.a4busuncached(A4UCH0) );

/*rv32cpu #(.RESETVECTOR(32'h80000000), .HARTID(1)) HART1 (
	.aclk(aclk),
	.aresetn(aresetn),
	.a4buscached(A4CH1),
	.a4busuncached(A4UCH1) );*/

// ----------------------------------------------------------------------------
// Cached devices
// ----------------------------------------------------------------------------
/*axicrossbar cachedmemorycrossbar (
  .aclk(aclk),
  .aresetn(aresetn),
  .s_axi_awid({1'b0, 1'b0}), //{A4CH0.awid, A4CH1.awid}
  .s_axi_awaddr({A4CH0.awaddr, A4CH1.awaddr}),
  .s_axi_awlen({A4CH0.awlen, A4CH1.awlen}),
  .s_axi_awsize({A4CH0.awsize, A4CH1.awsize}),
  .s_axi_awburst({A4CH0.awburst, A4CH1.awburst}),
  .s_axi_awlock({1'b0, 1'b0}), // {A4CH0.awlock, A4CH1.awlock}
  .s_axi_awcache({4'h0, 4'h0}), // {A4CH0.awcache, A4CH1.awcache}
  .s_axi_awprot({3'b000, 3'b000}), // {A4CH0.awprot, A4CH1.awprot}
  .s_axi_awqos({4'h0, 4'h0}), // {A4CH0.awqos, A4CH1.awqos}
  .s_axi_awvalid({A4CH0.awvalid, A4CH1.awvalid}),
  .s_axi_awready({A4CH0.awready, A4CH1.awready}),
  .s_axi_wdata({A4CH0.wdata, A4CH1.wdata}),
  .s_axi_wstrb({A4CH0.wstrb, A4CH1.wstrb}),
  .s_axi_wlast({A4CH0.wlast, A4CH1.wlast}),
  .s_axi_wvalid({A4CH0.wvalid, A4CH1.wvalid}),
  .s_axi_wready({A4CH0.wready, A4CH1.wready}),
  .s_axi_bid(), // {A4CH0.bid, A4CH1.bid}
  .s_axi_bresp({A4CH0.bresp, A4CH1.bresp}),
  .s_axi_bvalid({A4CH0.bvalid, A4CH1.bvalid}),
  .s_axi_bready({A4CH0.bready, A4CH1.bready}),
  .s_axi_arid({1'b0, 1'b0}), // {A4CH0.arid, A4CH1.arid}
  .s_axi_araddr({A4CH0.araddr, A4CH1.araddr}),
  .s_axi_arlen({A4CH0.arlen, A4CH1.arlen}),
  .s_axi_arsize({A4CH0.arsize, A4CH1.arsize}),
  .s_axi_arburst({A4CH0.arburst, A4CH1.arburst}),
  .s_axi_arlock({1'b0, 1'b0}), // {A4CH0.arlock, A4CH1.arlock}
  .s_axi_arcache({4'h0, 4'h0}), // {A4CH0.arcache, A4CH1.arcache}
  .s_axi_arprot({3'b000, 3'b000}), // {A4CH0.arprot, A4CH1.arprot}
  .s_axi_arqos({4'h0, 4'h0}), // {A4CH0.arqos, A4CH1.arqos}
  .s_axi_arvalid({A4CH0.arvalid, A4CH1.arvalid}),
  .s_axi_arready({A4CH0.arready, A4CH1.arready}),
  .s_axi_rid(), // {A4CH0.rid, A4CH1.rid}
  .s_axi_rdata({A4CH0.rdata, A4CH1.rdata}),
  .s_axi_rresp({A4CH0.rresp, A4CH1.rresp}),
  .s_axi_rlast({A4CH0.rlast, A4CH1.rlast}),
  .s_axi_rvalid({A4CH0.rvalid, A4CH1.rvalid}),
  .s_axi_rready({A4CH0.rready, A4CH1.rready}),
  .m_axi_awid(), // brambus.awid
  .m_axi_awaddr(brambus.awaddr),
  .m_axi_awlen(brambus.awlen),
  .m_axi_awsize(brambus.awsize),
  .m_axi_awburst(brambus.awburst),
  .m_axi_awlock(), // brambus.awlock
  .m_axi_awcache(), // brambus.awcache
  .m_axi_awprot(), // brambus.awprot
  .m_axi_awregion(), // brambus.awregion
  .m_axi_awqos(), // brambus.awqos
  .m_axi_awvalid(brambus.awvalid),
  .m_axi_awready(brambus.awready),
  .m_axi_wdata(brambus.wdata),
  .m_axi_wstrb(brambus.wstrb),
  .m_axi_wlast(brambus.wlast),
  .m_axi_wvalid(brambus.wvalid),
  .m_axi_wready(brambus.wready),
  .m_axi_bid(1'b0), // brambus.bid
  .m_axi_bresp(brambus.bresp),
  .m_axi_bvalid(brambus.bvalid),
  .m_axi_bready(brambus.bready),
  .m_axi_arid(), // brambus.arid
  .m_axi_araddr(brambus.araddr),
  .m_axi_arlen(brambus.arlen),
  .m_axi_arsize(brambus.arsize),
  .m_axi_arburst(brambus.arburst),
  .m_axi_arlock(), // brambus.arlock
  .m_axi_arcache(), // brambus.arcache
  .m_axi_arprot(), // brambus.arprot
  .m_axi_arregion(), // brambus.arregion
  .m_axi_arqos(), // brambus.arqos
  .m_axi_arvalid(brambus.arvalid),
  .m_axi_arready(brambus.arready),
  .m_axi_rid(1'b0), // brambus.rid
  .m_axi_rdata(brambus.rdata),
  .m_axi_rresp(brambus.rresp),
  .m_axi_rlast(brambus.rlast),
  .m_axi_rvalid(brambus.rvalid),
  .m_axi_rready(brambus.rready) );*/

a4bram BRAM64(
	.aclk(aclk),
	.aresetn(aresetn),
	.s_axi(A4CH0/*brambus*/) );

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
