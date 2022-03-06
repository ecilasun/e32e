`timescale 1ns / 1ps

import axi_pkg::*;

module cacheddevicechain(
	input wire aclk,
	input wire aresetn,
	axi_if.slave axi4if);

// ------------------------------------------------------------------------------------
// Cached memory devices
// ------------------------------------------------------------------------------------

// ddr3 @00000000 (512MBytes)
/*wire validwaddr_ddr3 = axi4if.awaddr>=32'h00000000 && axi4if.awaddr<32'h20000000;
wire validraddr_ddr3 = axi4if.araddr>=32'h00000000 && axi4if.araddr<32'h20000000;
axi_if ddr3if();
a4ddr3 DDR3512M(
	.aclk(aclk),
	.aresetn(aresetn),
	.s_axi(ddr3if) );*/

// bram @20000000
wire validwaddr_bram = axi4if.awaddr>=32'h20000000 && axi4if.awaddr<32'h20010000;
wire validraddr_bram = axi4if.araddr>=32'h20000000 && axi4if.araddr<32'h20010000;
axi_if bramif();
a4bram BRAM64(
	.aclk(aclk),
	.aresetn(aresetn),
	.s_axi(bramif) );

// framebuffer0 @40000000
/*wire validwaddr_fb = axi4if.awaddr>=32'h40000000 && axi4if.awaddr<32'h40020000;
wire validraddr_fb = axi4if.araddr>=32'h40000000 && axi4if.araddr<32'h40020000;
axi_if fbif();
axi4fb framebufferunit(
	.aclk(aclk),
	.aresetn(aresetn),
	.axi4if(fbif) );*/

// ------------------------------------------------------------------------------------
// write router
// ------------------------------------------------------------------------------------

wire [31:0] waddr = {3'b000, axi4if.awaddr[28:0]};

always_comb begin
	bramif.awaddr = validwaddr_bram ? waddr : 32'dz;
	bramif.awvalid = validwaddr_bram ? axi4if.awvalid : 1'b0;
	bramif.awlen = validwaddr_bram ? axi4if.awlen : 0;
	bramif.awsize = validwaddr_bram ? axi4if.awsize : 0;
	bramif.awburst = validwaddr_bram ? axi4if.awburst : 0;
	bramif.wdata = validwaddr_bram ? axi4if.wdata : 32'dz;
	bramif.wstrb = validwaddr_bram ? axi4if.wstrb : 4'h0;
	bramif.wvalid = validwaddr_bram ? axi4if.wvalid : 1'b0;
	bramif.bready = validwaddr_bram ? axi4if.bready : 1'b0;
	bramif.wlast = validwaddr_bram ? axi4if.wlast : 1'b0;

	/*fbif.awaddr = validwaddr_fb ? waddr : 32'dz;
	fbif.awvalid = validwaddr_fb ? axi4if.awvalid : 1'b0;
	fbif.awlen = validwaddr_fb ? axi4if.awlen : 0;
	fbif.awsize = validwaddr_fb ? axi4if.awsize : 0;
	fbif.awburst = validwaddr_fb ? axi4if.awburst : 0;
	fbif.wdata = validwaddr_fb ? axi4if.wdata : 32'dz;
	fbif.wstrb = validwaddr_fb ? axi4if.wstrb : 4'h0;
	fbif.wvalid = validwaddr_fb ? axi4if.wvalid : 1'b0;
	fbif.bready = validwaddr_fb ? axi4if.bready : 1'b0;
	fbif.wlast = validwaddr_fb ? axi4if.wlast : 1'b0;*/

	if (validwaddr_bram) begin
		axi4if.awready = bramif.awready;
		axi4if.bresp = bramif.bresp;
		axi4if.bvalid = bramif.bvalid;
		axi4if.wready = bramif.wready;
	/*end else if (validwaddr_fb) begin
		axi4if.awready = fbif.awready;
		axi4if.bresp = fbif.bresp;
		axi4if.bvalid = fbif.bvalid;
		axi4if.wready = fbif.wready;*/
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

	bramif.araddr = validraddr_bram ? raddr : 32'dz;
	bramif.arlen = validraddr_bram ? axi4if.arlen : 0;
	bramif.arsize = validraddr_bram ? axi4if.arsize : 0;
	bramif.arburst = validraddr_bram ? axi4if.arburst : 0;
	bramif.arvalid = validraddr_bram ? axi4if.arvalid : 1'b0;
	bramif.rready = validraddr_bram ? axi4if.rready : 1'b0;

	/*fbif.araddr = validraddr_fb ? raddr : 32'dz;
	fbif.arlen = validraddr_fb ? axi4if.arlen : 0;
	fbif.arsize = validraddr_fb ? axi4if.arsize : 0;
	fbif.arburst = validraddr_fb ? axi4if.arburst : 0;
	fbif.arvalid = validraddr_fb ? axi4if.arvalid : 1'b0;
	fbif.rready = validraddr_fb ? axi4if.rready : 1'b0;*/

	if (validraddr_bram) begin
		axi4if.arready = bramif.arready;
		axi4if.rdata = bramif.rdata;
		axi4if.rresp = bramif.rresp;
		axi4if.rvalid = bramif.rvalid;
		axi4if.rlast = bramif.rlast;
	/*end else if (validraddr_fb) begin
		axi4if.arready = fbif.arready;
		axi4if.rdata = fbif.rdata;
		axi4if.rresp = fbif.rresp;
		axi4if.rvalid = fbif.rvalid;
		axi4if.rlast = fbif.rlast;*/
	end else begin
		axi4if.arready = 0;
		axi4if.rdata = 0;
		axi4if.rresp = 0;
		axi4if.rvalid = 0;
		axi4if.rlast = 0;
	end
end

endmodule
