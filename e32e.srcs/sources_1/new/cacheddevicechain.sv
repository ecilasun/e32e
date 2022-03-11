`timescale 1ns / 1ps

import axi_pkg::*;

module cacheddevicechain(
	input wire aclk,
	input wire bramclk,
	input wire aresetn,
	input wire clk_sys_i,
	input wire clk_ref_i,
	output wire calib_done,
	output wire ui_clk,
	//ddr3devicewires.def ddr3wires,
	axi_if.slave axi4if);

// ------------------------------------------------------------------------------------
// Cached memory devices
// ------------------------------------------------------------------------------------

// ddr3 @00000000 (512MBytes)
/*logic validwaddr_ddr3 = 1'b0, validraddr_ddr3 = 1'b0;*/
// bram @20000000
logic validwaddr_bram = 1'b0, validraddr_bram = 1'b0;

always_comb begin
	/*validwaddr_ddr3 = (axi4if.awaddr>=32'h00000000) && (axi4if.awaddr<32'h20000000);
	validraddr_ddr3 = (axi4if.araddr>=32'h00000000) && (axi4if.araddr<32'h20000000);*/
	validwaddr_bram = (axi4if.awaddr>=32'h20000000) && (axi4if.awaddr<32'h20010000);
	validraddr_bram = (axi4if.araddr>=32'h20000000) && (axi4if.araddr<32'h20010000);
end

axi_if ddr3if();
/*axi4ddr3 DDR3512M(
	.aclk(aclk),
	.aresetn(aresetn),
	.clk_sys_i(clk_sys_i),
	.clk_ref_i(clk_ref_i),
	.m_axi(ddr3if),
	.ddr3wires(ddr3wires),
	.calib_done(calib_done),
	.ui_clk(ui_clk) );*/

axi_if bramif();
a4bram BRAM64(
	.aclk(aclk),
	.bramclk(bramclk),
	.aresetn(aresetn),
	.s_axi(bramif) );

// ------------------------------------------------------------------------------------
// write router
// ------------------------------------------------------------------------------------

wire [31:0] waddr = {3'b000, axi4if.awaddr[28:0]};

always_comb begin
	bramif.awaddr = validwaddr_bram ? waddr : 'dz;
	bramif.awvalid = validwaddr_bram ? axi4if.awvalid : 1'b0;
	bramif.awlen = validwaddr_bram ? axi4if.awlen : 0;
	bramif.awsize = validwaddr_bram ? axi4if.awsize : 0;
	bramif.awburst = validwaddr_bram ? axi4if.awburst : 0;
	bramif.wdata = validwaddr_bram ? axi4if.wdata : 'dz;
	bramif.wstrb = validwaddr_bram ? axi4if.wstrb : 'd0;
	bramif.wvalid = validwaddr_bram ? axi4if.wvalid : 1'b0;
	bramif.bready = validwaddr_bram ? axi4if.bready : 1'b0;
	bramif.wlast = validwaddr_bram ? axi4if.wlast : 1'b0;

	/*ddr3if.awaddr = validwaddr_ddr3 ? waddr : 'dz;
	ddr3if.awvalid = validwaddr_ddr3 ? axi4if.awvalid : 1'b0;
	ddr3if.awlen = validwaddr_ddr3 ? axi4if.awlen : 0;
	ddr3if.awsize = validwaddr_ddr3 ? axi4if.awsize : 0;
	ddr3if.awburst = validwaddr_ddr3 ? axi4if.awburst : 0;
	ddr3if.wdata = validwaddr_ddr3 ? axi4if.wdata : 'dz;
	ddr3if.wstrb = validwaddr_ddr3 ? axi4if.wstrb : 'd0;
	ddr3if.wvalid = validwaddr_ddr3 ? axi4if.wvalid : 1'b0;
	ddr3if.bready = validwaddr_ddr3 ? axi4if.bready : 1'b0;
	ddr3if.wlast = validwaddr_ddr3 ? axi4if.wlast : 1'b0;*/

	if (validwaddr_bram) begin
		axi4if.awready = bramif.awready;
		axi4if.bresp = bramif.bresp;
		axi4if.bvalid = bramif.bvalid;
		axi4if.wready = bramif.wready;
	/*end else if (validwaddr_ddr3) begin
		axi4if.awready = ddr3if.awready;
		axi4if.bresp = ddr3if.bresp;
		axi4if.bvalid = ddr3if.bvalid;
		axi4if.wready = ddr3if.wready;*/
	end else begin
		axi4if.awready = 0;
		axi4if.bresp = 0;
		axi4if.bvalid = 0;
		axi4if.wready = 0;
	end
end

// ------------------------------------------------------------------------------------
// read router
// ------------------------------------------------------------------------------------

wire [31:0] raddr = {3'b000, axi4if.araddr[28:0]};

always_comb begin
	bramif.araddr = validraddr_bram ? raddr : 'dz;
	bramif.arlen = validraddr_bram ? axi4if.arlen : 0;
	bramif.arsize = validraddr_bram ? axi4if.arsize : 0;
	bramif.arburst = validraddr_bram ? axi4if.arburst : 0;
	bramif.arvalid = validraddr_bram ? axi4if.arvalid : 1'b0;
	bramif.rready = validraddr_bram ? axi4if.rready : 1'b0;

	/*ddr3if.araddr = validraddr_ddr3 ? raddr : 'dz;
	ddr3if.arlen = validraddr_ddr3 ? axi4if.arlen : 0;
	ddr3if.arsize = validraddr_ddr3 ? axi4if.arsize : 0;
	ddr3if.arburst = validraddr_ddr3 ? axi4if.arburst : 0;
	ddr3if.arvalid = validraddr_ddr3 ? axi4if.arvalid : 1'b0;
	ddr3if.rready = validraddr_ddr3 ? axi4if.rready : 1'b0;*/

	if (validraddr_bram) begin
		axi4if.arready = bramif.arready;
		axi4if.rdata = bramif.rdata;
		axi4if.rresp = bramif.rresp;
		axi4if.rvalid = bramif.rvalid;
		axi4if.rlast = bramif.rlast;
	/*end else if (validraddr_ddr3) begin
		axi4if.arready = ddr3if.arready;
		axi4if.rdata = ddr3if.rdata;
		axi4if.rresp = ddr3if.rresp;
		axi4if.rvalid = ddr3if.rvalid;
		axi4if.rlast = ddr3if.rlast;*/
	end else begin
		axi4if.arready = 0;
		axi4if.rdata = 0;
		axi4if.rresp = 0;
		axi4if.rvalid = 0;
		axi4if.rlast = 0;
	end
end

endmodule
