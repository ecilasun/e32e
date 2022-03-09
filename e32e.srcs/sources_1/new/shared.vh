// ------------------------------------------
// Integer uncompressed instructions (2'b11)
// ------------------------------------------

`define OPCODE_OP		    7'b0110011
`define OPCODE_OP_IMM 	    7'b0010011
`define OPCODE_LUI		    7'b0110111
`define OPCODE_STORE	    7'b0100011
`define OPCODE_LOAD		    7'b0000011
`define OPCODE_JAL		    7'b1101111
`define OPCODE_JALR		    7'b1100111
`define OPCODE_BRANCH	    7'b1100011
`define OPCODE_AUIPC	    7'b0010111
`define OPCODE_FENCE	    7'b0001111
`define OPCODE_SYSTEM	    7'b1110011
`define OPCODE_FLOAT_OP     7'b1010011
`define OPCODE_FLOAT_LDW    7'b0000111
`define OPCODE_FLOAT_STW    7'b0100111
`define OPCODE_FLOAT_MADD   7'b1000011
`define OPCODE_FLOAT_MSUB   7'b1000111
`define OPCODE_FLOAT_NMSUB  7'b1001011
`define OPCODE_FLOAT_NMADD  7'b1001111

// ------------------------------------------
// Sub-instructions
// ------------------------------------------

// Flow control
`define F3_BEQ		3'b000
`define F3_BNE		3'b001
`define F3_BLT		3'b100
`define F3_BGE		3'b101
`define F3_BLTU		3'b110
`define F3_BGEU		3'b111

// Logic ops
`define F3_ADD		3'b000
`define F3_SLL		3'b001
`define F3_SLT		3'b010
`define F3_SLTU		3'b011
`define F3_XOR		3'b100
`define F3_SR		3'b101
`define F3_OR		3'b110
`define F3_AND		3'b111

// Integer math
`define F3_MUL		3'b000
`define F3_MULH		3'b001
`define F3_MULHSU	3'b010
`define F3_MULHU	3'b011
`define F3_DIV		3'b100
`define F3_DIVU		3'b101
`define F3_REM		3'b110
`define F3_REMU		3'b111

// Load type
`define F3_LB		3'b000
`define F3_LH		3'b001
`define F3_LW		3'b010
`define F3_LBU		3'b100
`define F3_LHU		3'b101

// Store type
`define F3_SB		3'b000
`define F3_SH		3'b001
`define F3_SW		3'b010

// Float compare type
`define F3_FEQ		3'b010
`define F3_FLT		3'b001
`define F3_FLE		3'b000

// Floating point math
`define F7_FADD        7'b0000000
`define F7_FSUB        7'b0000100
`define F7_FMUL        7'b0001000
`define F7_FDIV        7'b0001100
`define F7_FSQRT       7'b0101100

// Sign injection
`define F7_FSGNJ       7'b0010000
`define F7_FSGNJN      7'b0010000
`define F7_FSGNJX      7'b0010000

// Comparison / classification
`define F7_FMIN        7'b0010100
`define F7_FMAX        7'b0010100
`define F7_FEQ         7'b1010000
`define F7_FLT         7'b1010000
`define F7_FLE         7'b1010000
`define F7_FCLASS      7'b1110000

// Conversion from/to integer
`define F7_FCVTWS      7'b1100000
`define F7_FCVTWUS     7'b1100000
`define F7_FCVTSW      7'b1101000
`define F7_FCVTSWU     7'b1101000

// Move from/to integer registers
`define F7_FMVXW       7'b1110000
`define F7_FMVWX       7'b1111000

// ------------------------------------------
// Instruction decoder one-hot states
// ------------------------------------------

`define O_H_OP				17
`define O_H_OP_IMM			16
`define O_H_LUI				15
`define O_H_STORE			14
`define O_H_LOAD			13
`define O_H_JAL				12
`define O_H_JALR			11
`define O_H_BRANCH			10
`define O_H_AUIPC			9
`define O_H_FENCE			8
`define O_H_SYSTEM			7
`define O_H_FLOAT_OP		6
`define O_H_FLOAT_LDW		5
`define O_H_FLOAT_STW		4
`define O_H_FLOAT_MADD		3
`define O_H_FLOAT_MSUB		2
`define O_H_FLOAT_NMSUB		1
`define O_H_FLOAT_NMADD		0

// ------------------------------------------
// ALU ops
// ------------------------------------------

// Integer base
`define ALU_NONE		4'd0
`define ALU_ADD 		4'd1
`define ALU_SUB			4'd2
`define ALU_SLL			4'd3
`define ALU_SLT			4'd4
`define ALU_SLTU		4'd5
`define ALU_XOR			4'd6
`define ALU_SRL			4'd7
`define ALU_SRA			4'd8
`define ALU_OR			4'd9
`define ALU_AND			4'd10
// Mul/Div extension
`define ALU_MUL			4'd11
`define ALU_DIV			4'd12
`define ALU_REM			4'd13

// Branch
`define BLU_NONE		3'd0
`define BLU_EQ			3'd1
`define BLU_NE			3'd2
`define BLU_L			3'd3
`define BLU_GE			3'd4
`define BLU_LU			3'd5
`define BLU_GEU			3'd6

// ------------------------------------------
// CSR
// ------------------------------------------

`define CSR_REGISTER_COUNT 16

`define CSR_MCAUSE		5'd0
`define CSR_MSTATUS		5'd1
`define CSR_MIE			5'd2
`define CSR_MTVEC		5'd3
`define CSR_MEPC		5'd4
`define CSR_MHARTID		5'd5
`define CSR_MTVAL		5'd6
`define CSR_MIP			5'd7
`define CSR_TIMECMPLO	5'd8
`define CSR_TIMECMPHI	5'd9
`define CSR_CYCLELO		5'd10
`define CSR_CYCLEHI		5'd11
`define CSR_TIMELO		5'd12
`define CSR_RETILO		5'd13
`define CSR_TIMEHI		5'd14
`define CSR_RETIHI		5'd15
