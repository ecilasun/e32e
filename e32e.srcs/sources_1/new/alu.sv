`timescale 1ns / 1ps

`include "shared.vh"

module arithmeticlogicunit(
	input wire enable,
	input wire aclk,
	output logic [31:0] aluout,
	input wire [31:0] val1,
	input wire [31:0] val2,
	input wire [3:0] aluop );

logic [31:0] v1 = 0;
logic [31:0] v2 = 0;
logic [3:0] op = 0;

wire [9:0] aluonehot = {
	op == `ALU_ADD  ? 1'b1 : 1'b0,
	op == `ALU_SUB  ? 1'b1 : 1'b0,
	op == `ALU_SLL  ? 1'b1 : 1'b0,
	op == `ALU_SLT  ? 1'b1 : 1'b0,
	op == `ALU_SLTU ? 1'b1 : 1'b0,
	op == `ALU_XOR  ? 1'b1 : 1'b0,
	op == `ALU_SRL  ? 1'b1 : 1'b0,
	op == `ALU_SRA  ? 1'b1 : 1'b0,
	op == `ALU_OR   ? 1'b1 : 1'b0,
	op == `ALU_AND  ? 1'b1 : 1'b0 };

always @(posedge aclk) begin
	if (enable) begin
		v1 <= val1;
		v2 <= val2;
		op <= aluop;
	end
end

logic [31:0] vsum;
logic [31:0] vdiff;
logic [31:0] vshl;
logic [31:0] vsless;
logic [31:0] vless;
logic [31:0] vxor;
logic [31:0] vshr;
logic [31:0] vsra;
logic [31:0] vor;
logic [31:0] vand;

always_comb begin
	vsum = v1 + v2;
	vdiff = v1 + (~v2 + 32'd1); // v1 - v2;
	vshl = v1 << v2[4:0];
	vsless = $signed(v1) < $signed(v2) ? 32'd1 : 32'd0;
	vless = v1 < v2 ? 32'd1 : 32'd0;
	vxor = v1 ^ v2;
	vshr = v1 >> v2[4:0];
	vsra = $signed(v1) >>> v2[4:0];
	vor = v1 | v2;
	vand = v1 & v2;
end

always_comb begin
	case (1'b1)
		// integer ops
		default:		aluout = vsum; // aluonehot[9]
		aluonehot[8]:	aluout = vdiff;
		aluonehot[7]:	aluout = vshl;
		aluonehot[6]:	aluout = vsless;
		aluonehot[5]:	aluout = vless;
		aluonehot[4]:	aluout = vxor;
		aluonehot[3]:	aluout = vshr;
		aluonehot[2]:	aluout = vsra;
		aluonehot[1]:	aluout = vor;
		aluonehot[0]:	aluout = vand;
	endcase
end

endmodule
