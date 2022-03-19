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
	wire [11:0] irq,
	input wire [63:0] wallclocktime,
	input wire [63:0] cpuclocktime,
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

wire isuncached = addr[31]; // NOTE: anything at and above 0x80000000 is uncached memory

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

typedef enum logic [3:0] {INIT, RETIRE, FETCH, EXECUTE, STOREWAIT, LOADWAIT, IMATHWAIT, INTERRUPTSETUP, INTERRUPTVALUE, INTERRUPTCAUSE, WFI} cpustatetype;
cpustatetype cpustate = INIT;

logic [31:0] PC = RESETVECTOR;
logic [31:0] nextPC = RESETVECTOR;
logic [63:0] retired = 0;

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

// CSR shadows
wire [31:0] mip;	// Interrupt pending
wire [31:0] mie;	// Interrupt enable
wire [31:0] mtvec;	// Interrupt handler vector
wire [31:0] mepc;	// Interrupt return address
wire [31:0] mtval;	// Interrupt time value
wire [31:0] mcause;	// Interrupt cause bits
wire [63:0] tcmp;	// Time compare

// CSR access
logic csrwe = 1'b0;
logic [31:0] csrdin = 0;
logic [31:0] csrprevval;
logic csrwenforce = 1'b0;
logic [4:0] csrenforceindex = 0;
wire [31:0] csrdout;

csrregisterfile #(.HARTID(HARTID)) CSRREGS (
	.clock(aclk),
	.wallclocktime(wallclocktime),
	.cpuclocktime(cpuclocktime),
	.retired(retired),
	.tcmp(tcmp),
	.mie(mie),
	.mip(mip),
	.mtvec(mtvec),
	.mepc(mepc),
	.csrindex(csrwenforce ? csrenforceindex : csrindex),
	.we(csrwe),
	.dout(csrdout),
	.din(csrdin) );

// BLU
wire branchout;

branchdecision BLU(
	.enable(rready & (cpustate == FETCH)),
	.aclk(aclk),
	.branchout(branchout),
	.val1(rval1),
	.val2(rval2),
	.bluop(bluop) );

// ALU
wire [31:0] aluout;

arithmeticlogicunit ALU (
	.enable(rready & (cpustate == FETCH)),
	.aclk(aclk),
	.aluout(aluout),
	.val1(rval1),
	.val2(immsel ? immed : rval2),
	.aluop(aluop) );

// MUL/DIV/REM
wire isexecuting = (cpustate==EXECUTE);
wire isexecutingop = isexecuting & instrOneHotOut[`O_H_OP];

wire mulready;
wire mulstart = isexecutingop & (aluop==`ALU_MUL);
wire [31:0] product;
integermultiplier IMULSU(
    .aclk(aclk),
    .aresetn(aresetn),
    .start(mulstart),
    .ready(mulready),
    .func3(func3),
    .multiplicand(rval1),
    .multiplier(rval2),
    .product(product) );

wire divuready;
wire divustart = isexecutingop & (aluop==`ALU_DIV | aluop==`ALU_REM);
wire [31:0] quotientu, remainderu;
integerdividerunsigned IDIVU (
	.aclk(aclk),
	.aresetn(aresetn),
	.start(divustart),
	.ready(divuready),
	.dividend(rval1),
	.divisor(rval2),
	.quotient(quotientu),
	.remainder(remainderu) );

wire divready;
wire divstart = isexecutingop & (aluop==`ALU_DIV | aluop==`ALU_REM);
wire [31:0] quotient, remainder;
integerdividersigned IDIVS (
	.aclk(aclk),
	.aresetn(aresetn),
	.start(divstart),
	.ready(divready),
	.dividend(rval1),
	.divisor(rval2),
	.quotient(quotient),
	.remainder(remainder) );

wire imathstart = divstart | divustart | mulstart;
wire imathready = divready | divuready | mulready;

// Interrupt logic
logic illegalinstruction = 1'b0;
logic [31:0] rwaddress = 32'd0;
logic [31:0] adjacentPC = 32'd0;

// Retired instruction counter
always @(posedge aclk) begin
	retired <= retired + (cpustate==RETIRE ? 64'd1 : 64'd0);
end

// Timer trigger
wire trq = (wallclocktime >= tcmp) ? 1'b1 : 1'b0;

// Any external wire event triggers our interrupt service if corresponding enable bit is high
wire hwint = (|irq) && mie[11]; // MEIE - machine external interrupt enable
// TODO: No timer interrupts yet (also, check corresponding enable bit)
wire timerint = trq && mie[7]; // MTIE - timer interrupt enable
// TODO: for later
//wire swint = sint && mie[3] // MSIE - machine software interrupt enable

always @(posedge aclk) begin
	if (~aresetn) begin
		cpustate <= INIT;
	end else begin

		wstrb <= 4'h0;
	 	ren <= 1'b0;
	 	rwe <= 1'b0;
	 	csrwe <= 1'b0;
	 	csrwenforce <= 1'b0;

		case (cpustate)
			INIT: begin
				addr <= RESETVECTOR;
				PC <= RESETVECTOR;
				nextPC <= RESETVECTOR;
				cpustate <= RETIRE;
			end

			RETIRE: begin
				if ( (illegalinstruction || hwint || timerint) && ~(|mip) ) begin
					csrwe <= 1'b1;
					csrwenforce <= 1'b1;
					csrdin <= nextPC;
					csrenforceindex <= `CSR_MEPC;
					PC <= mtvec;
					cpustate <= INTERRUPTSETUP;
				end else begin
					// Regular instruction fetch
					PC <= nextPC;
					addr <= nextPC;
					cpustate <= FETCH;
					ifetch <= 1'b1; // This read is to use I$, hold high until read is complete
					ren <= 1'b1;
				end
			end

			INTERRUPTSETUP: begin
				csrwe <= 1'b1;
				csrwenforce <= 1'b1;
				csrenforceindex <= `CSR_MIP;
				// NOTE: Interrupt service ordering according to privileged isa is: mei/msi/mti/sei/ssi/sti
				if (hwint) begin // mei, external hardware interrupt
					csrdin <= {mip[31:12], 1'b1, mip[10:0]};
				end else if (illegalinstruction /*|| ecall*/) begin // msi, exception
					csrdin <= {mip[31:4], 1'b1, mip[2:0]};
				end else if (timerint) begin // mti, timer interrupt
					csrdin <= {mip[31:8], 1'b1, mip[6:0]};
				end
				cpustate <= INTERRUPTVALUE;
			end
			
			INTERRUPTVALUE: begin
				csrwe <= 1'b1;
				csrwenforce <= 1'b1;
				csrenforceindex <= `CSR_MTVAL;
				if (hwint) begin // mei, external hardware interrupt
					csrdin  <= {20'd0, irq};
				end else if (illegalinstruction /*|| ecall*/) begin // msi, exception
					csrdin <= 32'd0;// TODO: write offending instruction here
				end else if (timerint) begin // mti, timer interrupt
					csrdin  <= 32'd0;
				end
				cpustate <= INTERRUPTCAUSE;
			end

			INTERRUPTCAUSE: begin
				csrwe <= 1'b1;
				csrwenforce <= 1'b1;
				csrenforceindex <= `CSR_MCAUSE;
				if (hwint) begin // mei, external hardware interrupt
					csrdin  <= 32'h8000000b; // [31]=1'b1(interrupt), 11->h/w
				end else if (illegalinstruction /*|| ecall*/) begin // msi, exception
					csrdin  <= /*ecall ? 32'h0000000b :*/ 32'h00000002; // [31]=1'b0(exception), 0xb->ecall, 0x2->illegal instruction
				end else if (timerint) begin // mti, timer interrupt
					csrdin  <= 32'h80000007; // [31]=1'b1(interrupt), 7->timer
				end
				addr <= mtvec;
				ifetch <= 1'b1; // We can now resume reading the first trap handler instruction
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
				rwe <= imathstart ? 1'b0 : isrecordingform;
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
						cpustate <= imathstart ? IMATHWAIT : RETIRE;
						rdin <= aluout;
					end
					/*instrOneHotOut[`O_H_FLOAT_LDW],*/
					instrOneHotOut[`O_H_LOAD]: begin
						addr <= rwaddress;
						ren <= 1'b1; // This read is to use D$ (i.e. ifetch == 0 here)
						cpustate <= LOADWAIT;
					end
					/*instrOneHotOut[`O_H_FLOAT_STW],*/
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
								dout <= /*instrOneHotOut[`O_H_FLOAT_STW] ? frval2 :*/ rval2;
								wstrb <= 4'b1111;
							end
						endcase
						addr <= rwaddress;
						cpustate <= STOREWAIT;
					end
					/*instrOneHotOut[`O_H_FENCE]: begin
						// 0000_pred_succ_00000_000_00000_0001111 -> FENCE
						// 0000_0000_0000_00000_001_00000_0001111 -> FENCE.I (flush I$)
					end*/
					instrOneHotOut[`O_H_SYSTEM]: begin
						// Store previous value of CSR in target register
						rdin <= csrprevval;
						rwe <= (func3 == 3'b000) ? 1'b0 : 1'b1; // No register write back for non-CSR sys ops
						csrwe <= 1'b1;
						case (func3)
							default/*3'b000*/: begin
								case (func12)
									default/*12'b0000000_00000*/: begin	// ECALL - sys call
										//ecall <= msena;
										// Ignore store
										csrwe <= 1'b0;
									end
									12'b0000000_00001: begin			// EBREAK - software breakpoint
										//ebreak <= msena;
										// Ignore store
										csrwe <= 1'b0;
									end
									12'b0001000_00101: begin			// WFI - wait for interrupt
										cpustate <= WFI;
										// Ignore store
										csrwe <= 1'b0;
									end
									12'b0011000_00010: begin			// MRET - return from interrupt
										// Ignore whatever random CSR might be selected, and use ours
										csrwenforce <= 1'b1;
										csrenforceindex <= `CSR_MIP;
										// Return to interrupt point
										nextPC <= mepc;
										// Clear interrupt pending bit with correct priority
										if (mip[11])
											csrdin <= {mip[31:12], 1'b0, mip[10:0]};
										else if (mip[3])
											csrdin <= {mip[31:4], 1'b0, mip[2:0]};
										else if (mip[7])
											csrdin <= {mip[31:8], 1'b0, mip[6:0]};
									end
								endcase
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
				rwe <= rready;
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
						/*if (instrOneHotOut[`O_H_FLOAT_LDW]) begin
							frdin <= din[31:0];
							frwe <= rready;
							rwe <= 1'b0; // Do not overwrite integer registers in this case
						end else*/
							rdin <= din[31:0];
					end
				endcase
				cpustate <= rready ? RETIRE : LOADWAIT;
			end

			IMATHWAIT: begin
				if (imathready) begin
					rwe <= 1'b1;
					case (aluop)
						`ALU_MUL: begin
							rdin <= product;
						end
						`ALU_DIV: begin
							rdin <= func3==`F3_DIV ? quotient : quotientu;
						end
						`ALU_REM: begin
							rdin <= func3==`F3_REM ? remainder : remainderu;
						end
						default: begin
							rdin <= 32'd0;
						end
					endcase
					cpustate <= RETIRE;
				end else begin
					cpustate <= IMATHWAIT;
				end
			end
			
			WFI: begin
				// Everything except illegalinstruction wakes us up
				if ( (hwint || timerint) && ~(|mip) ) begin
					cpustate <= RETIRE;
				end else begin
					cpustate <= WFI;
				end
			end

		endcase

	end
end

endmodule
