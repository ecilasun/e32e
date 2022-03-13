`timescale 1ns / 1ps

module axi4ddr3(
	input wire aclk,
	input wire aresetn,
	input wire clk_sys_i,
	input wire clk_ref_i,
	axi_if.slave m_axi,
	ddr3devicewires.def ddr3wires,
	output wire calib_done );

ddr3drv ddr3driver(
	.aclk(aclk),
	.aresetn(aresetn),
	.clk_sys_i(clk_sys_i),
	.clk_ref_i(clk_ref_i),
	.m_axi(m_axi),
	.ddr3wires(ddr3wires),
	.calib_done(calib_done) );

endmodule
