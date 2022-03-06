`timescale 1ns / 1ps

import axi_pkg::*;

`include "shared.vh"

// ----------------------------------------------------------------------------
// CPU
// ----------------------------------------------------------------------------

module rv32cpu #(
	parameter int RESETVECTOR = 32'h20000000,
	parameter int HARTID = 32'h00000000
) (
	input wire aclk,
	input wire aresetn,
	axi_if.master a4buscached,
	axi_if.master a4busuncached );

// Memory wires
logic ifetch = 1'b0;			// I$/D$ select
addr_t addr = RESETVECTOR;		// Memory address
logic ren = 1'b0;				// Read enable
logic [3:0] wstrb = 4'h0;		// Write strobe
wire [31:0] din;				// Input to CPU
logic [31:0] dout;				// Output from CPU
wire wready, rready;			// Cache r/w state

// Address space is arranged so that device addresses below 0x80000000 are cached
// DDR3: 00000000..20000000 : cached r/w
// BRAM: 20000000..2000FFFF : cached r/w
// ... : 20001000..3FFFFFFF : unused
// FB0 : 40000000..4001FFFF : cached r/w
// FB1 : 40020000..4002FFFF : cached r/w
// PAL : 40040000..400400FF : cached r/w
// GCTL: 40080000..400800FF : cached r/w
// ... : 40080100..7FFFFFFF : unused
// MAIL: 80000000..80000FFF : uncached r/w
// UART: 80001000..8000100F : uncached r/w
// SPI : 80001010..8000101F : uncached r/w
// PS/2: 80001020..8000102F : uncached r/w
// BTN : 80001030..8000103F : uncached r/w
// LED : 80001040..8000104F : uncached r/w
// ... : 80001050..FFFFFFFF : unused
wire isuncached = addr[31]; // Anything at and above 0x8... is uncached memory

systemcache CACHE(
	.aclk(aclk),
	.aresetn(aresetn),
	.uncached(isuncached),
	// From CPU
	.ifetch(ifetch),
	.addr(addr),
	.din(dout),
	.dout(din),
	.wstrb(wstrb),
	.ren(ren),
	.wready(wready),
	.rready(rready),
	.a4buscached(a4buscached),
	.a4busuncached(a4busuncached) );

typedef enum logic [3:0] {INIT, RETIRE, FETCH, EXECUTE, STOREWAIT, LOADWAIT} cpustatetype;
cpustatetype cpustate = INIT;

logic [31:0] PC = RESETVECTOR;
logic [31:0] nextPC = RESETVECTOR;

wire [17:0] instrOneHotOut;
wire [3:0] aluop;
wire [2:0] bluop;
wire [2:0] func3;
wire [6:0] func7;
wire [11:0] func12;
wire [4:0] rs1, rs2, rs3, rd, csrindex;
wire [31:0] immed;
wire immsel, isrecordingform;

instructiondecoder DECODER(
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

registerfile REGS(
	.clock(aclk),
	.rs1(rs1),
	.rs2(rs2),
	.rd(rd),
	.wren(rwe),
	.din(rdin),
	.rval1(rval1),
	.rval2(rval2) );

logic csrwe = 1'b0;
logic [31:0] csrdin = 0;
logic [31:0] csrprevval;
wire [31:0] csrdout;
csrregisterfile #(.HARTID(HARTID)) CSRREGS (
	.clock(aclk),
	.csrindex(csrindex),
	.we(csrwe),
	.dout(csrdout),
	.din(csrdin) );

wire branchout;

branchdecision BLU(
	.enable(rready & (cpustate == FETCH)),
	.aclk(aclk),
	.branchout(branchout),
	.val1(rval1),
	.val2(rval2),
	.bluop(bluop) );

wire [31:0] aluout;

arithmeticlogicunit ALU (
	.enable(rready & (cpustate == FETCH)),
	.aclk(aclk),
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
	 	csrwe <= 1'b0;

		case (cpustate)
			INIT: begin
				addr <= RESETVECTOR;
				PC <= RESETVECTOR;
				nextPC <= RESETVECTOR;
				cpustate <= RETIRE;
			end

			RETIRE: begin
				PC <= nextPC;
				addr <= nextPC;
				ifetch <= 1'b1; // This read is to use I$, hold high until read is complete
				ren <= 1'b1;
				cpustate <= FETCH;
			end

			FETCH: begin
				adjacentPC <= PC + 32'd4;
				ifetch <= ~rready;
				rwaddress <= rval1 + immed;
				csrprevval <= csrdout;
				cpustate <= rready ? EXECUTE : FETCH;
			end

			EXECUTE: begin
				cpustate <= RETIRE;
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
					end*/
					instrOneHotOut[`O_H_SYSTEM]: begin
						rdin <= csrprevval;
						rwe <= 1'b1;
						csrwe <= 1'b1;
						case (func3)
							default/*3'b000*/: begin
								csrdin <= csrprevval;
								csrwe <= 1'b0;
							end
							3'b001: begin
								csrdin <= rval1;
							end
							3'b101: begin
								csrdin <= immed;
							end
							3'b010: begin
								csrdin <= csrprevval | rval1;
							end
							3'b110: begin
								csrdin <= csrprevval | immed;
							end
							3'b011: begin
								csrdin <= csrprevval & (~rval1);
							end
							3'b111: begin
								csrdin <= csrprevval & (~immed);
							end
						endcase
					end
					default: begin
						illegalinstruction <= 1'b1;
					end
				endcase
			end

			STOREWAIT: begin
				cpustate <= wready ? RETIRE : STOREWAIT;
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
				cpustate <= rready ? RETIRE : LOADWAIT;
			end

		endcase

	end
end

endmodule
