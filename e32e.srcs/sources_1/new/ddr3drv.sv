`timescale 1ns / 1ps

import axi_pkg::*;

module ddr3drv(
	input wire aclk,
	input wire aresetn,
	input wire clk_sys_i,
	input wire clk_ref_i,
	axi_if.slave m_axi,
	ddr3devicewires.def ddr3wires,
	output wire calib_done,
	output wire ui_clk );

axi_if s_axi();

axi_clock_converter_0 AXI4ClkConv (
  .s_axi_aclk(ui_clk),          // input wire s_axi_aclk
  .s_axi_aresetn(aresetn),    // input wire s_axi_aresetn
  .s_axi_awaddr(m_axi.awaddr),      // input wire [31 : 0] s_axi_awaddr
  .s_axi_awlen(m_axi.awlen),        // input wire [7 : 0] s_axi_awlen
  .s_axi_awsize(m_axi.awsize),      // input wire [2 : 0] s_axi_awsize
  .s_axi_awburst(m_axi.awburst),    // input wire [1 : 0] s_axi_awburst
  .s_axi_awlock(1'b0),      // input wire [0 : 0] s_axi_awlock
  .s_axi_awcache(4'b0011),    // input wire [3 : 0] s_axi_awcache
  .s_axi_awprot(3'b000),      // input wire [2 : 0] s_axi_awprot
  .s_axi_awregion(4'h0),  // input wire [3 : 0] s_axi_awregion
  .s_axi_awqos(4'h0),        // input wire [3 : 0] s_axi_awqos
  .s_axi_awvalid(m_axi.awvalid),    // input wire s_axi_awvalid
  .s_axi_awready(m_axi.awready),    // output wire s_axi_awready
  .s_axi_wdata(m_axi.wdata),        // input wire [127 : 0] s_axi_wdata
  .s_axi_wstrb(m_axi.wstrb),        // input wire [15 : 0] s_axi_wstrb
  .s_axi_wlast(m_axi.wlast),        // input wire s_axi_wlast
  .s_axi_wvalid(m_axi.wvalid),      // input wire s_axi_wvalid
  .s_axi_wready(m_axi.wready),      // output wire s_axi_wready
  .s_axi_bresp(m_axi.bresp),        // output wire [1 : 0] s_axi_bresp
  .s_axi_bvalid(m_axi.bvalid),      // output wire s_axi_bvalid
  .s_axi_bready(m_axi.bready),      // input wire s_axi_bready
  .s_axi_araddr(m_axi.araddr),      // input wire [31 : 0] s_axi_araddr
  .s_axi_arlen(m_axi.arlen),        // input wire [7 : 0] s_axi_arlen
  .s_axi_arsize(m_axi.arsize),      // input wire [2 : 0] s_axi_arsize
  .s_axi_arburst(m_axi.arburst),    // input wire [1 : 0] s_axi_arburst
  .s_axi_arlock(1'b0),      // input wire [0 : 0] s_axi_arlock
  .s_axi_arcache(4'b0011),    // input wire [3 : 0] s_axi_arcache
  .s_axi_arprot(3'b000),      // input wire [2 : 0] s_axi_arprot
  .s_axi_arregion(4'h0),  // input wire [3 : 0] s_axi_arregion
  .s_axi_arqos(4'h0),        // input wire [3 : 0] s_axi_arqos
  .s_axi_arvalid(m_axi.arvalid),    // input wire s_axi_arvalid
  .s_axi_arready(m_axi.arready),    // output wire s_axi_arready
  .s_axi_rdata(m_axi.rdata),        // output wire [127 : 0] s_axi_rdata
  .s_axi_rresp(m_axi.rresp),        // output wire [1 : 0] s_axi_rresp
  .s_axi_rlast(m_axi.rlast),        // output wire s_axi_rlast
  .s_axi_rvalid(m_axi.rvalid),      // output wire s_axi_rvalid
  .s_axi_rready(m_axi.rready),      // input wire s_axi_rready

  .m_axi_aclk(aclk),          		// input wire m_axi_aclk
  .m_axi_aresetn(aresetn),    		// input wire m_axi_aresetn
  .m_axi_awaddr(s_axi.awaddr),      // output wire [31 : 0] m_axi_awaddr
  .m_axi_awlen(s_axi.awlen),        // output wire [7 : 0] m_axi_awlen
  .m_axi_awsize(s_axi.awsize),      // output wire [2 : 0] m_axi_awsize
  .m_axi_awburst(s_axi.awburst),    // output wire [1 : 0] m_axi_awburst
  .m_axi_awlock(),      // output wire [0 : 0] m_axi_awlock
  .m_axi_awcache(),    // output wire [3 : 0] m_axi_awcache
  .m_axi_awprot(),      // output wire [2 : 0] m_axi_awprot
  .m_axi_awregion(),  // output wire [3 : 0] m_axi_awregion
  .m_axi_awqos(),        // output wire [3 : 0] m_axi_awqos
  .m_axi_awvalid(s_axi.awvalid),    // output wire m_axi_awvalid
  .m_axi_awready(s_axi.awready),    // input wire m_axi_awready
  .m_axi_wdata(s_axi.wdata),        // output wire [127 : 0] m_axi_wdata
  .m_axi_wstrb(s_axi.wstrb),        // output wire [15 : 0] m_axi_wstrb
  .m_axi_wlast(s_axi.wlast),        // output wire m_axi_wlast
  .m_axi_wvalid(s_axi.wvalid),      // output wire m_axi_wvalid
  .m_axi_wready(s_axi.wready),      // input wire m_axi_wready
  .m_axi_bresp(s_axi.bresp),        // input wire [1 : 0] m_axi_bresp
  .m_axi_bvalid(s_axi.bvalid),      // input wire m_axi_bvalid
  .m_axi_bready(s_axi.bready),      // output wire m_axi_bready
  .m_axi_araddr(s_axi.araddr),      // output wire [31 : 0] m_axi_araddr
  .m_axi_arlen(s_axi.arlen),        // output wire [7 : 0] m_axi_arlen
  .m_axi_arsize(s_axi.arsize),      // output wire [2 : 0] m_axi_arsize
  .m_axi_arburst(s_axi.arburst),    // output wire [1 : 0] m_axi_arburst
  .m_axi_arlock(),      // output wire [0 : 0] m_axi_arlock
  .m_axi_arcache(),    // output wire [3 : 0] m_axi_arcache
  .m_axi_arprot(),      // output wire [2 : 0] m_axi_arprot
  .m_axi_arregion(),  // output wire [3 : 0] m_axi_arregion
  .m_axi_arqos(),        // output wire [3 : 0] m_axi_arqos
  .m_axi_arvalid(s_axi.arvalid),    // output wire m_axi_arvalid
  .m_axi_arready(s_axi.arready),    // input wire m_axi_arready
  .m_axi_rdata(s_axi.rdata),        // input wire [127 : 0] m_axi_rdata
  .m_axi_rresp(s_axi.rresp),        // input wire [1 : 0] m_axi_rresp
  .m_axi_rlast(s_axi.rlast),        // input wire m_axi_rlast
  .m_axi_rvalid(s_axi.rvalid),      // input wire m_axi_rvalid
  .m_axi_rready(s_axi.rready)      // output wire m_axi_rready
);

wire ui_clk_sync_rst;

/*mig_7series_0 ddr3instance (
    // memory interface ports
    .ddr3_addr                      (ddr3wires.ddr3_addr),
    .ddr3_ba                        (ddr3wires.ddr3_ba),
    .ddr3_cas_n                     (ddr3wires.ddr3_cas_n),
    .ddr3_ck_n                      (ddr3wires.ddr3_ck_n),
    .ddr3_ck_p                      (ddr3wires.ddr3_ck_p),
    .ddr3_cke                       (ddr3wires.ddr3_cke),
    .ddr3_ras_n                     (ddr3wires.ddr3_ras_n),
    .ddr3_reset_n                   (ddr3wires.ddr3_reset_n),
    .ddr3_we_n                      (ddr3wires.ddr3_we_n),
    .ddr3_dq                        (ddr3wires.ddr3_dq),
    .ddr3_dqs_n                     (ddr3wires.ddr3_dqs_n),
    .ddr3_dqs_p                     (ddr3wires.ddr3_dqs_p),
    .ddr3_dm                        (ddr3wires.ddr3_dm),
    .ddr3_odt                       (ddr3wires.ddr3_odt),

    // application interface ports
    .ui_clk                         (ui_clk),          // feeds back into axi4if.aclk to drive the entire bus
    .ui_clk_sync_rst                (ui_clk_sync_rst),
    .init_calib_complete            (calib_done),
    .device_temp					(), // unused

    .mmcm_locked                    (), // unused
    .aresetn                        (aresetn),

    .app_sr_req                     (1'b0), // unused
    .app_ref_req                    (1'b0), // unused
    .app_zq_req                     (1'b0), // unused
    .app_sr_active                  (), // unused
    .app_ref_ack                    (), // unused
    .app_zq_ack                     (), // unused

    // slave interface write address ports
    .s_axi_awid                     (4'h0),
    .s_axi_awaddr                   (s_axi.awaddr[28:0]),
    .s_axi_awlen                    (s_axi.awlen),
    .s_axi_awsize                   (s_axi.awsize),
    .s_axi_awburst                  (s_axi.awburst),
    .s_axi_awlock                   (1'b0),
    .s_axi_awcache                  (4'b0011),
    .s_axi_awprot                   (3'b000),
    .s_axi_awqos                    (4'h0),
    .s_axi_awvalid                  (s_axi.awvalid),
    .s_axi_awready                  (s_axi.awready),

    // slave interface write data ports
    .s_axi_wdata                    (s_axi.wdata),
    .s_axi_wstrb                    (s_axi.wstrb),
    .s_axi_wlast                    (s_axi.wlast),
    .s_axi_wvalid                   (s_axi.wvalid),
    .s_axi_wready                   (s_axi.wready),

    // slave interface write response ports
    .s_axi_bid                      (), // unused
    .s_axi_bresp                    (s_axi.bresp),
    .s_axi_bvalid                   (s_axi.bvalid),
    .s_axi_bready                   (s_axi.bready),

    // slave interface read address ports
    .s_axi_arid                     (4'h0),
    .s_axi_araddr                   (s_axi.araddr[28:0]),
    .s_axi_arlen                    (s_axi.arlen),
    .s_axi_arsize                   (s_axi.arsize),
    .s_axi_arburst                  (s_axi.arburst),
    .s_axi_arlock                   (1'b0),
    .s_axi_arcache                  (4'b0011),
    .s_axi_arprot                   (3'b000),
    .s_axi_arqos                    (4'h0),
    .s_axi_arvalid                  (s_axi.arvalid),
    .s_axi_arready                  (s_axi.arready),

    // slave interface read data ports
    .s_axi_rid                      (), // unused
    .s_axi_rdata                    (s_axi.rdata),
    .s_axi_rresp                    (s_axi.rresp),
    .s_axi_rlast                    (s_axi.rlast),
    .s_axi_rvalid                   (s_axi.rvalid),
    .s_axi_rready                   (s_axi.rready),
    // system clock ports
    .sys_clk_i                      (clk_sys_i), // 100mhz
    // reference clock ports
    .clk_ref_i                      (clk_ref_i), // 200mhz
    .sys_rst                        (aresetn) );*/

endmodule
