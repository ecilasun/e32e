`timescale 1ns / 1ps

import axi_pkg::*;

`include "shared.vh"

// ----------------------------------------------------------------------------
// CPU with FPU
// ----------------------------------------------------------------------------

module rv32cpu #(
	parameter int RESETVECTOR = 32'h20000000,
	parameter int HARTID = 32'h00000000
) (
	input wire aclk,
	input wire aresetn,
	wire [4:0] irq, // Top bit is HART IRQ
	input wire [63:0] wc0,
	input wire [63:0] cc0,
	axi_if.master a4buscached,
	axi_if.master a4busuncached );

`define ENABLEFPU
`include "rv32.vi"

endmodule
