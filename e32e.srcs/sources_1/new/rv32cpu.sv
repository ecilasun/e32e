`timescale 1ns / 1ps

import axi_pkg::*;

`include "shared.vh"

// ----------------------------------------------------------------------------
// CPU
// ----------------------------------------------------------------------------

module rv32cpu #(
	parameter int RESETVECTOR = 32'h80000000,
	parameter int HARTID = 32'h00000000
) (
	input wire aclk,
	input wire aresetn,
	output addr_t addr,
	output logic [3:0] wstrb,
	output logic ren,
	output logic ifetch,
	input wire [31:0] din,
	output logic [31:0] dout,
	input wire wready,
	input wire rready );

typedef enum logic [3:0] {INIT, RETIRE, FETCH, DECODE, EXECUTE, STOREWAIT, LOADWAIT, WBACK} cpustatetype;
cpustatetype cpustate = INIT;

logic [31:0] PC = RESETVECTOR;
logic [31:0] nextPC = RESETVECTOR;

wire [17:0] instrOneHotOut;
wire [3:0] aluop;
wire [2:0] bluop;
wire [2:0] func3;
wire [6:0] func7;
wire [11:0] func12;
wire [4:0] rs1;
wire [4:0] rs2;
wire [4:0] rs3;
wire [4:0] rd;
wire [4:0] csrindex;
wire [31:0] immed;
wire immsel;

decoder InstructionDecoder(
	.enable(rready & (cpustate == FETCH)),
	.instruction(din),
	.instrOneHotOut(instrOneHotOut),
	.isrecordingform(isrecordingform),
	.aluop(aluop),
	.bluop(bluop),
	.func3(func3),
	.func7(func7),
	.func12(func12),
	.rs1(rs1),
	.rs2(rs2),
	.rs3(rs3),
	.rd(rd),
	.csrindex(csrindex),
	.immed(immed),
	.selectimmedasrval2(immsel) );

logic rwe = 1'b0;
wire [31:0] rval1;
wire [31:0] rval2;
logic [31:0] rdin;

registerfile IntegerRegisters(
	.clock(aclk),
	.rs1(rs1),
	.rs2(rs2),
	.rd(rd),
	.wren(rwe),
	.din(rdin),
	.rval1(rval1),
	.rval2(rval2) );

wire branchout;

BLU BranchUnit(
	.enable(cpustate==DECODE),
	.branchout(branchout),
	.val1(rval1),
	.val2(rval2),
	.bluop(bluop) );

wire [31:0] aluout;

ALU ArithmeticLogicUnit(
	.enable(cpustate==DECODE),
	.aluout(aluout),
	.func3(func3),
	.val1(rval1),
	.val2(immsel ? immed : rval2),
	.aluop(aluop) );

logic illegalinstruction = 1'b0;
logic [31:0] rwaddress = 32'd0;
logic [31:0] adjacentPC = 32'd0;

always @(posedge aclk) begin
	if (~aresetn) begin
		cpustate <= INIT;
	end else begin

		wstrb <= 4'h0;
	 	ren <= 1'b0;
	 	rwe <= 1'b0;

		case (cpustate)
			INIT: begin
				addr <= RESETVECTOR;
				PC <= RESETVECTOR;
				cpustate <= RETIRE;
			end

			RETIRE: begin
				addr <= PC;
				ifetch <= 1'b1; // This read is to use I$, hold high until read is complete
				ren <= 1'b1;
				cpustate <= FETCH;
			end

			FETCH: begin
				adjacentPC <= PC + 32'd4;
				cpustate <= rready ? DECODE : FETCH;
			end

			DECODE: begin
				ifetch <= 1'b0;
				rwaddress <= rval1 + immed;
				cpustate <= EXECUTE;
			end

			EXECUTE: begin
				cpustate <= WBACK;
				rwe <= isrecordingform;
				illegalinstruction <= 1'b0;
				nextPC <= adjacentPC;
				case (1'b1)
					instrOneHotOut[`O_H_AUIPC]: begin
						rdin <= PC + immed;
					end
					instrOneHotOut[`O_H_LUI]: begin
						rdin <= immed;
					end
					instrOneHotOut[`O_H_JAL]: begin
						rdin <= adjacentPC;
						nextPC <= PC + immed;
					end
					instrOneHotOut[`O_H_JALR]: begin
						rdin <= adjacentPC;
						nextPC <= rwaddress;
					end
					instrOneHotOut[`O_H_BRANCH]: begin
						nextPC <= branchout == 1'b1 ? (PC + immed) : adjacentPC;
					end
					instrOneHotOut[`O_H_OP], instrOneHotOut[`O_H_OP_IMM]: begin
						rdin <= aluout;
					end
					instrOneHotOut[`O_H_LOAD]: begin
						addr <= rwaddress;
						ren <= 1'b1; // This read is to use D$ (i.e. ifetch == 0 here)
						cpustate <= LOADWAIT;
					end
					instrOneHotOut[`O_H_STORE]: begin
						case (func3)
							3'b000: begin // BYTE
								dout <= {rval2[7:0], rval2[7:0], rval2[7:0], rval2[7:0]};
								case (rwaddress[1:0])
									2'b11: begin wstrb <= 4'b1000; end
									2'b10: begin wstrb <= 4'b0100; end
									2'b01: begin wstrb <= 4'b0010; end
									default/*2'b00*/: begin wstrb <= 4'b0001; end
								endcase
							end
							3'b001: begin // WORD
								dout <= {rval2[15:0], rval2[15:0]};
								case (rwaddress[1])
									1'b1: begin wstrb <= 4'b1100; end
									default/*1'b0*/: begin wstrb <= 4'b0011; end
								endcase
							end
							default: begin // DWORD
								dout <= rval2;
								wstrb <= 4'b1111;
							end
						endcase
						addr <= rwaddress;
						cpustate <= STOREWAIT;
					end
					/*instrOneHotOut[`O_H_FENCE]: begin
					end
					instrOneHotOut[`O_H_SYSTEM]: begin
					end*/
					default: begin
						illegalinstruction <= 1'b1;
					end
				endcase
			end

			STOREWAIT: begin
				cpustate <= wready ? WBACK : STOREWAIT;
			end

			LOADWAIT: begin
				// Read complete, handle register write-back
				case (func3)
					3'b000: begin // BYTE with sign extension
						case (rwaddress[1:0])
							2'b11: begin rdin <= {{24{din[31]}}, din[31:24]}; end
							2'b10: begin rdin <= {{24{din[23]}}, din[23:16]}; end
							2'b01: begin rdin <= {{24{din[15]}}, din[15:8]}; end
							default/*2'b00*/: begin rdin <= {{24{din[7]}}, din[7:0]}; end
						endcase
					end
					3'b001: begin // HALF with sign extension
						case (rwaddress[1])
							1'b1: begin rdin <= {{16{din[31]}}, din[31:16]}; end
							default/*1'b0*/: begin rdin <= {{16{din[15]}}, din[15:0]}; end
						endcase
					end
					3'b100: begin // BYTE with zero extension
						case (rwaddress[1:0])
							2'b11: begin rdin <= {24'd0, din[31:24]}; end
							2'b10: begin rdin <= {24'd0, din[23:16]}; end
							2'b01: begin rdin <= {24'd0, din[15:8]}; end
							default/*2'b00*/: begin rdin <= {24'd0, din[7:0]}; end
						endcase
					end
					3'b101: begin // HALF with zero extension
						case (rwaddress[1])
							1'b1: begin rdin <= {16'd0, din[31:16]}; end
							default/*1'b0*/: begin rdin <= {16'd0, din[15:0]}; end
						endcase
					end
					default/*3'b010*/: begin // WORD
						rdin <= din[31:0];
					end
				endcase
				rwe <= rready;
				cpustate <= rready ? WBACK : LOADWAIT;
			end

			default/*WBACK*/: begin
				PC <= nextPC;
				cpustate <= RETIRE;
			end
		endcase

	end
end

endmodule
