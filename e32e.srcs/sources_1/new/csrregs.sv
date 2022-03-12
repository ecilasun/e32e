`timescale 1ns / 1ps

`include "shared.vh"

module csrregisterfile #(
	parameter int HARTID = 32'h00000000
) (
	input wire clock,
	input wire [63:0] wallclocktime,
	input wire [63:0] cpuclocktime,
	input wire [63:0] retired,
	input wire [4:0] csrindex,
	input wire we,
	output logic [31:0] dout,
	input wire [31:0] din );

logic [31:0] csrreg [0:`CSR_REGISTER_COUNT-1];
logic csrwe = 1'b0;
logic [31:0] csrin = 32'd0;
logic [31:0] csrval = 32'd0;

// see https://cv32e40p.readthedocs.io/en/latest/control_status_registers/#cs-registers for defaults
initial begin
	csrreg[`CSR_MCAUSE]		= 32'd0;
	csrreg[`CSR_MSTATUS]	= 32'h00001800; // mpp (machine previous priviledge mode 12:11) hardwired to 2'b11 on startup
	csrreg[`CSR_MIE]		= 32'd0;
	csrreg[`CSR_MTVEC]		= 32'd0;
	csrreg[`CSR_MEPC]		= 32'd0;
	csrreg[`CSR_MHARTID]	= HARTID;
	csrreg[`CSR_MTVAL]		= 32'd0;
	csrreg[`CSR_MIP]		= 32'd0;
	csrreg[`CSR_TIMECMPLO]	= 32'hffffffff; // timecmp = 0xffffffffffffffff
	csrreg[`CSR_TIMECMPHI]	= 32'hffffffff;
	csrreg[`CSR_CYCLELO]	= 32'd0;
	csrreg[`CSR_CYCLEHI]	= 32'd0;
	csrreg[`CSR_TIMELO]		= 32'd0;
	csrreg[`CSR_RETILO]		= 32'd0;
	csrreg[`CSR_TIMEHI]		= 32'd0;
	csrreg[`CSR_RETIHI]		= 32'd0;
end

always @(posedge clock) begin
	if (we)
		csrreg[csrindex] <= din;
end

always_comb begin
	case(csrindex)
		`CSR_MCAUSE,
		`CSR_MSTATUS,
		`CSR_MIE,
		`CSR_MTVEC,
		`CSR_MEPC,
		`CSR_MTVAL,
		`CSR_MIP,
		`CSR_TIMECMPLO,
		`CSR_TIMECMPHI:	dout = csrreg[csrindex];
		`CSR_MHARTID:	dout = HARTID; // Immutable
		`CSR_CYCLELO:	dout = cpuclocktime[31:0];
		`CSR_CYCLEHI:	dout = cpuclocktime[63:32];
		`CSR_TIMELO:	dout = wallclocktime[31:0];
		`CSR_TIMEHI:	dout = wallclocktime[63:32];
		`CSR_RETILO:	dout = retired[31:0];
		`CSR_RETIHI:	dout = retired[63:32];
		default:		dout = 0;
	endcase
end

endmodule
