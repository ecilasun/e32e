`timescale 1ns / 1ps

`include "shared.vh"

module csrregisterfile #(
	parameter int HARTID = 32'h00000000
) (
	input wire clock,
	input wire [63:0] wallclocktime,
	input wire [63:0] cpuclocktime,
	input wire [63:0] retired,
	output logic [63:0] tcmp = 64'hFFFFFFFFFFFFFFFF,
	output logic [31:0] mie = 0,
	output logic [31:0] mip = 0,
	output logic [31:0] mtvec = 0,
	output logic [31:0] mepc = 0,
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
	// Writes always go to internal registers
	// TODO: Ignore ones that don't make sense to store
	if (we) begin
		csrreg[csrindex] <= din;
		// Reflect to shadow copy
		case(csrindex)
			`CSR_MIE:		mie <= din;
			`CSR_MIP:		mip <= din;
			`CSR_MTVEC:		mtvec <= din;
			`CSR_TIMECMPLO:	tcmp[31:0] <= din;
			`CSR_TIMECMPHI:	tcmp[63:32] <= din;
			`CSR_MEPC:		mepc <= din;
			default:	;
		endcase
	end
end

always_comb begin
	case(csrindex)
		// Reads from internal register file
		`CSR_MTVAL,
		`CSR_MCAUSE,
		`CSR_MSTATUS:	dout = csrreg[csrindex];
		// Reads routed to external wires
		`CSR_MEPC:		dout = mepc;
		`CSR_TIMECMPLO:	dout = tcmp[31:0];
		`CSR_TIMECMPHI:	dout = tcmp[63:32];
		`CSR_MIE:		dout = mie;
		`CSR_MIP:		dout = mip;
		`CSR_MTVEC:		dout = mtvec;
		`CSR_MHARTID:	dout = HARTID; // Immutable
		`CSR_CYCLELO:	dout = cpuclocktime[31:0];
		`CSR_CYCLEHI:	dout = cpuclocktime[63:32];
		`CSR_TIMELO:	dout = wallclocktime[31:0];
		`CSR_TIMEHI:	dout = wallclocktime[63:32];
		`CSR_RETILO:	dout = retired[31:0];
		`CSR_RETIHI:	dout = retired[63:32];
		// Unknown register reads return zero (TODO: Also cause an exception?)
		default:		dout = 0;
	endcase
end

endmodule
