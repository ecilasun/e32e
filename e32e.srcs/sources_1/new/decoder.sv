`timescale 1ns / 1ps

`include "shared.vh"

module instructiondecoder(
	input wire aresetn,
	input wire aclk,
	input wire enable,
	input wire [31:0] instruction,		// Raw input instruction
	output bit [17:0] instrOneHotOut,	// Current instruction class
	output bit isrecordingform,			// High when we can save result to register
	output bit [3:0] aluop,				// Current ALU op
	output bit [2:0] bluop,				// Current BLU op
	output bit [2:0] func3,				// Sub-instruction
	output bit [6:0] func7,				// Sub-instruction
	output bit [11:0] func12,			// Sub-instruction
	output bit [4:0] rs1,				// Source register one
	output bit [4:0] rs2,				// Source register two
	output bit [4:0] rs3,				// Used by fused multiplyadd/sub
	output bit [4:0] rd,				// Destination register
	output bit [4:0] csrindex,			// Index of selected CSR register
	output bit [31:0] immed,			// Unpacked immediate integer value
	output bit selectimmedasrval2		// Select rval2 or unpacked integer during EXEC
);

logic [31:0] instrlatch;

always_latch begin
	if (~aresetn) begin
		instrlatch <= 32'd0;
	end else begin
		if (enable) instrlatch <= instruction;
	end
end

wire [17:0] instrOneHot = {
	instrlatch[6:0]==`OPCODE_OP ? 1'b1:1'b0,
	instrlatch[6:0]==`OPCODE_OP_IMM ? 1'b1:1'b0,
	instrlatch[6:0]==`OPCODE_LUI ? 1'b1:1'b0,
	instrlatch[6:0]==`OPCODE_STORE ? 1'b1:1'b0,
	instrlatch[6:0]==`OPCODE_LOAD ? 1'b1:1'b0,
	instrlatch[6:0]==`OPCODE_JAL ? 1'b1:1'b0,
	instrlatch[6:0]==`OPCODE_JALR ? 1'b1:1'b0,
	instrlatch[6:0]==`OPCODE_BRANCH ? 1'b1:1'b0,
	instrlatch[6:0]==`OPCODE_AUIPC ? 1'b1:1'b0,
	instrlatch[6:0]==`OPCODE_FENCE ? 1'b1:1'b0,
	instrlatch[6:0]==`OPCODE_SYSTEM ? 1'b1:1'b0,
	instrlatch[6:0]==`OPCODE_FLOAT_OP ? 1'b1:1'b0,
	instrlatch[6:0]==`OPCODE_FLOAT_LDW ? 1'b1:1'b0,
	instrlatch[6:0]==`OPCODE_FLOAT_STW ? 1'b1:1'b0,
	instrlatch[6:0]==`OPCODE_FLOAT_MADD ? 1'b1:1'b0,
	instrlatch[6:0]==`OPCODE_FLOAT_MSUB ? 1'b1:1'b0,
	instrlatch[6:0]==`OPCODE_FLOAT_NMSUB ? 1'b1:1'b0,
	instrlatch[6:0]==`OPCODE_FLOAT_NMADD ? 1'b1:1'b0 };

//11:10 -> R/W mode
//9:8 -> lowest privilege level allowed
always_comb begin
	case ({instrlatch[31:25], instrlatch[24:20]})
		default: csrindex = `CSR_MCAUSE;	// Illegal instruction exception
		
		//12'hF15: csrindex = `CSR_UNUSED;	// mconfigptr, defaults to zero, no exception

		12'h300: csrindex = `CSR_MSTATUS;	// r/w
		12'h304: csrindex = `CSR_MIE;		// r/w
		12'h305: csrindex = `CSR_MTVEC;		// r/w [1:0]==2'b00->direct, ==2'b01->vectored
		12'h341: csrindex = `CSR_MEPC;		// r/w [1:0] always 2'b00 (or [0] always 1'b0)
		12'h342: csrindex = `CSR_MCAUSE;	// r/w
		12'h343: csrindex = `CSR_MTVAL;		// r/w excpt specific info such as faulty instruction
		12'h344: csrindex = `CSR_MIP;		// r/w
		
		//12'h340: scratch register for machine trap mscratch
		//12'h301: isa / extension type misa
		12'hF14: csrindex = `CSR_MHARTID;	// r

		12'h800: csrindex = `CSR_TIMECMPLO;	// r/w
		12'h801: csrindex = `CSR_TIMECMPHI;	// r/w

		12'hC00,
		12'hB00: csrindex = `CSR_CYCLELO;	// r/w
		12'hC80,
		12'hB80: csrindex = `CSR_CYCLEHI;	// r/w
		12'hC02,
		12'hB02: csrindex = `CSR_RETILO;	// r
		12'hC82,
		12'hB82: csrindex = `CSR_RETIHI;	// r

		12'hC01: csrindex = `CSR_TIMELO;	// r
		12'hC81: csrindex = `CSR_TIMEHI;	// r

		//12'h7B0: debug control and status register dcsr
		//12'h7B1: debug pc dpc
		//12'h7B2: debug scratch register dscratch0
		//12'h7B3: debug scratch register dscratch1
	endcase
end

// Immed vs rval2 selector
wire selector = instrOneHot[`O_H_JALR] | instrOneHot[`O_H_OP_IMM] | instrOneHot[`O_H_LOAD] | instrOneHot[`O_H_FLOAT_LDW] | instrOneHot[`O_H_FLOAT_STW] | instrOneHot[`O_H_STORE];

// Every instruction except SYS:3'b000, BRANCH, FPU ops and STORE are recoding form
// i.e. NOT (branch or store) OR (SYS AND at least one bit set)
wire isfpuopcode = 
	instrOneHot[`O_H_FLOAT_OP] |
	instrOneHot[`O_H_FLOAT_LDW] |
	instrOneHot[`O_H_FLOAT_STW] |
	instrOneHot[`O_H_FLOAT_MADD] |
	instrOneHot[`O_H_FLOAT_MSUB] |
	instrOneHot[`O_H_FLOAT_NMSUB] |
	instrOneHot[`O_H_FLOAT_NMADD];

// NOTE: Load _is_ recording form but it's delayed vs where we normaly flag 'recording', so it's omitted from list and handled mamually
wire recording = ~(instrOneHot[`O_H_BRANCH] | instrOneHot[`O_H_LOAD] | instrOneHot[`O_H_STORE] | isfpuopcode) | (instrOneHot[`O_H_SYSTEM] & (|func3));

// Source/destination register indices
wire [4:0] src1 = instrlatch[19:15];
wire [4:0] src2 = instrlatch[24:20];
wire [4:0] src3 = instrlatch[31:27];
wire [4:0] dest = instrlatch[11:7];

// Sub-functions
wire [2:0] f3 = instrlatch[14:12];
wire [6:0] f7 = instrlatch[31:25];
wire [11:0] f12 = instrlatch[31:20];
wire mathopsel = instrlatch[30];
wire muldiv = instrlatch[25];

wire [19:0] high20 = {20{instrlatch[31]}};

// Shift in decoded values
always_comb begin
	rs1 = src1;
	rs2 = src2;
	rs3 = src3;
	rd = dest;
	func3 = f3;
	func7 = f7;
	func12 = f12;
	instrOneHotOut = instrOneHot;
	selectimmedasrval2 = selector;	// Use rval2 or immed
	isrecordingform = recording;	// Everything except branches and store records result into rd
end

// Work out ALU op
always_comb begin
	case (1'b1)
		instrOneHot[`O_H_OP]: begin
			if (muldiv) begin // MUL/DIV
				case (f3)
					3'b000, 3'b001, 3'b010, 3'b011: aluop = `ALU_MUL;
					3'b100, 3'b101: aluop = `ALU_DIV;
					default/*3'b110, 3'b111*/: aluop = `ALU_REM;
				endcase
			end else begin
				case (f3)
					3'b000: aluop = instrOneHot[`O_H_OP_IMM] ? `ALU_ADD : (mathopsel ? `ALU_SUB : `ALU_ADD);
					3'b001: aluop = `ALU_SLL;
					3'b011: aluop = `ALU_SLTU;
					3'b010: aluop = `ALU_SLT;
					3'b110: aluop = `ALU_OR;
					3'b111: aluop = `ALU_AND;
					3'b101: aluop = mathopsel ? `ALU_SRA : `ALU_SRL;
					default/*3'b100*/: aluop = `ALU_XOR;
				endcase
			end
		end

		instrOneHot[`O_H_OP_IMM]: begin
			case (f3)
				3'b000: aluop = instrOneHot[`O_H_OP_IMM] ? `ALU_ADD : (mathopsel ? `ALU_SUB : `ALU_ADD);
				3'b001: aluop = `ALU_SLL;
				3'b011: aluop = `ALU_SLTU;
				3'b010: aluop = `ALU_SLT;
				3'b110: aluop = `ALU_OR;
				3'b111: aluop = `ALU_AND;
				3'b101: aluop = mathopsel ? `ALU_SRA : `ALU_SRL;
				default/*3'b100*/: aluop = `ALU_XOR;
			endcase
		end
		
		instrOneHot[`O_H_JALR]: begin
			aluop = `ALU_ADD;
		end

		default: begin
			aluop = `ALU_NONE;
		end
	endcase
end

// Work out BLU op
always_comb begin
	case (1'b1)
		instrOneHot[`O_H_BRANCH]: begin
			case (f3)
				3'b000: bluop = `BLU_EQ;
				3'b001: bluop = `BLU_NE;
				3'b011: bluop = `BLU_NONE;
				3'b010: bluop = `BLU_NONE;
				3'b110: bluop = `BLU_LU;
				3'b111: bluop = `BLU_GEU;
				3'b101: bluop = `BLU_GE;
				default/*3'b100*/: bluop = `BLU_L;
			endcase
		end

		default: begin
			bluop = `ALU_NONE;
		end
	endcase
end

// Work out immediate value
always_comb begin
	case (1'b1)
		default: /*instrOneHot[`O_H_LUI], instrOneHot[`O_H_AUIPC]:*/ begin	
			immed = {instrlatch[31:12], 12'd0};
		end

		instrOneHot[`O_H_FLOAT_STW], instrOneHot[`O_H_STORE]: begin
			immed = {high20, f7, dest};
		end

		instrOneHot[`O_H_OP_IMM], instrOneHot[`O_H_FLOAT_LDW], instrOneHot[`O_H_LOAD], instrOneHot[`O_H_JALR]: begin
			immed = {high20, f12};
		end

		instrOneHot[`O_H_JAL]: begin
			immed = {{12{instrlatch[31]}}, instrlatch[19:12], instrlatch[20], instrlatch[30:21], 1'b0};
		end

		instrOneHot[`O_H_BRANCH]: begin
			immed = {high20, instrlatch[7], instrlatch[30:25], instrlatch[11:8], 1'b0};
		end

		instrOneHot[`O_H_SYSTEM]: begin
			immed = {27'd0, src1};
		end
	endcase
end

endmodule
