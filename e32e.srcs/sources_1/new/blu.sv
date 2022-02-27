`timescale 1ns / 1ps

`include "shared.vh"

module BLU(
	input wire enable,
	output logic branchout,
	input wire [31:0] val1,
	input wire [31:0] val2,
	input wire [2:0] bluop);

logic branch = 1'b0;
logic [31:0] v1 = 0;
logic [31:0] v2 = 0;
logic [2:0] op = 0;

wire [5:0] aluonehot = {
	op == `BLU_EQ  ? 1'b1 : 1'b0,
	op == `BLU_NE  ? 1'b1 : 1'b0,
	op == `BLU_L   ? 1'b1 : 1'b0,
	op == `BLU_GE  ? 1'b1 : 1'b0,
	op == `BLU_LU  ? 1'b1 : 1'b0,
	op == `BLU_GEU ? 1'b1 : 1'b0 };

always_latch begin
	if (enable) begin
		v1 = val1;
		v2 = val2;
		op = bluop;
	end
end

logic eq, sless, less;

always_comb begin
	eq = v1 == v2 ? 1'b1 : 1'b0;
	sless = $signed(v1) < $signed(v2) ? 1'b1 : 1'b0;
	less = v1 < v2 ? 1'b1 : 1'b0;
end

always_comb begin
	case (1'b1)
		// branch alu
		default:		branchout = eq; // aluonehot[5]
		aluonehot[4]:	branchout = ~eq;
		aluonehot[3]:	branchout = sless;
		aluonehot[2]:	branchout = ~sless;
		aluonehot[1]:	branchout = less;
		aluonehot[0]:	branchout = ~less;
	endcase
end

endmodule
