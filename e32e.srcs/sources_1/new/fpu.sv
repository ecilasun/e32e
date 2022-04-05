`timescale 1ns / 1ps

module floatingpointunit(
	// Clock and reset
	input wire clock,
	input wire resetn,

	// Inputs
	input wire [31:0] frval1,
	input wire [31:0] frval2,
	input wire [31:0] frval3,

	// Strobe
	input wire fmaddstrobe,
	input wire fmsubstrobe,
	input wire fnmsubstrobe,
	input wire fnmaddstrobe,
	input wire faddstrobe,
	input wire fsubstrobe,
	input wire fmulstrobe,
	input wire fdivstrobe,
	input wire fi2fstrobe,
	input wire fui2fstrobe,
	input wire ff2istrobe,
	input wire ff2uistrobe,
	input wire fsqrtstrobe,
	input wire feqstrobe,
	input wire fltstrobe,
	input wire flestrobe,

	// Output
	output logic resultvalid,
	output logic [31:0] result );

wire fmaddresultvalid;
wire fmsubresultvalid;
wire fnmsubresultvalid;
wire fnmaddresultvalid;
wire faddresultvalid;
wire fsubresultvalid;
wire fmulresultvalid;
wire fdivresultvalid;
wire fi2fresultvalid;
wire fui2fresultvalid;
wire ff2iresultvalid;
wire ff2uiresultvalid;
wire fsqrtresultvalid;
wire feqresultvalid;
wire fltresultvalid;
wire fleresultvalid;

wire [31:0] fmaddresult;
wire [31:0] fmsubresult;
wire [31:0] fnmsubresult;
wire [31:0] fnmaddresult;
wire [31:0] faddresult;
wire [31:0] fsubresult;
wire [31:0] fmulresult;
wire [31:0] fdivresult;
wire [31:0] fi2fresult;
wire [31:0] fui2fresult;
wire [31:0] ff2iresult;
wire [31:0] ff2uiresult;
wire [31:0] fsqrtresult;
wire [7:0] feqresult;
wire [7:0] fltresult;
wire [7:0] fleresult;

always @(posedge clock) begin
	if (~resetn) begin
		resultvalid <= 1'b0;
	end else begin
		case (1'b1)
			fmaddresultvalid:	begin result <= fmaddresult; resultvalid <= 1'b1; end
			fmsubresultvalid:	begin result <= fmsubresult; resultvalid <= 1'b1; end
			fnmsubresultvalid:	begin result <= fnmsubresult; resultvalid <= 1'b1; end
			fnmaddresultvalid:	begin result <= fnmaddresult; resultvalid <= 1'b1; end
			faddresultvalid:	begin result <= faddresult; resultvalid <= 1'b1; end
			fsubresultvalid:	begin result <= fsubresult; resultvalid <= 1'b1; end
			fmulresultvalid:	begin result <= fmulresult; resultvalid <= 1'b1; end
			fdivresultvalid:	begin result <= fdivresult; resultvalid <= 1'b1; end
			fi2fresultvalid:	begin result <= fi2fresult; resultvalid <= 1'b1; end
			fui2fresultvalid:	begin result <= fui2fresult; resultvalid <= 1'b1; end
			ff2iresultvalid:	begin result <= ff2iresult; resultvalid <= 1'b1; end
			ff2uiresultvalid:	begin result <= ff2uiresult; resultvalid <= 1'b1; end
			fsqrtresultvalid:	begin result <= fsqrtresult; resultvalid <= 1'b1; end
			feqresultvalid:		begin result <= {24'd0, feqresult}; resultvalid <= 1'b1; end
			fltresultvalid:		begin result <= {24'd0, fltresult}; resultvalid <= 1'b1; end
			fleresultvalid:		begin result <= {24'd0, fleresult}; resultvalid <= 1'b1; end
			default:			begin result <= 32'd0; resultvalid <= 1'b0; end
		endcase
	end
end

fp_madd floatfmadd(
	.s_axis_a_tdata(frval1),
	.s_axis_a_tvalid(fmaddstrobe),
	.s_axis_b_tdata(frval2),
	.s_axis_b_tvalid(fmaddstrobe),
	.s_axis_c_tdata(frval3),
	.s_axis_c_tvalid(fmaddstrobe),
	.aclk(clock),
	.m_axis_result_tdata(fmaddresult),
	.m_axis_result_tvalid(fmaddresultvalid) );

fp_msub floatfmsub(
	.s_axis_a_tdata(frval1),
	.s_axis_a_tvalid(fmsubstrobe),
	.s_axis_b_tdata(frval2),
	.s_axis_b_tvalid(fmsubstrobe),
	.s_axis_c_tdata(frval3),
	.s_axis_c_tvalid(fmsubstrobe),
	.aclk(clock),
	.m_axis_result_tdata(fmsubresult),
	.m_axis_result_tvalid(fmsubresultvalid) );

fp_madd floatfnmsub(
	.s_axis_a_tdata({~frval1[31], frval1[30:0]}), // -A
	.s_axis_a_tvalid(fnmsubstrobe),
	.s_axis_b_tdata(frval2),
	.s_axis_b_tvalid(fnmsubstrobe),
	.s_axis_c_tdata(frval3),
	.s_axis_c_tvalid(fnmsubstrobe),
	.aclk(clock),
	.m_axis_result_tdata(fnmsubresult),
	.m_axis_result_tvalid(fnmsubresultvalid) );

fp_msub floatfnmadd(
	.s_axis_a_tdata({~frval1[31], frval1[30:0]}), // -A
	.s_axis_a_tvalid(fnmaddstrobe),
	.s_axis_b_tdata(frval2),
	.s_axis_b_tvalid(fnmaddstrobe),
	.s_axis_c_tdata(frval3),
	.s_axis_c_tvalid(fnmaddstrobe),
	.aclk(clock),
	.m_axis_result_tdata(fnmaddresult),
	.m_axis_result_tvalid(fnmaddresultvalid) );

fp_add floatadd(
	.s_axis_a_tdata(frval1),
	.s_axis_a_tvalid(faddstrobe),
	.s_axis_b_tdata(frval2),
	.s_axis_b_tvalid(faddstrobe),
	.aclk(clock),
	.m_axis_result_tdata(faddresult),
	.m_axis_result_tvalid(faddresultvalid) );

fp_sub floatsub(
	.s_axis_a_tdata(frval1),
	.s_axis_a_tvalid(fsubstrobe),
	.s_axis_b_tdata(frval2),
	.s_axis_b_tvalid(fsubstrobe),
	.aclk(clock),
	.m_axis_result_tdata(fsubresult),
	.m_axis_result_tvalid(fsubresultvalid) );

fp_mul floatmul(
	.s_axis_a_tdata(frval1),
	.s_axis_a_tvalid(fmulstrobe),
	.s_axis_b_tdata(frval2),
	.s_axis_b_tvalid(fmulstrobe),
	.aclk(clock),
	.m_axis_result_tdata(fmulresult),
	.m_axis_result_tvalid(fmulresultvalid) );

fp_div floatdiv(
	.s_axis_a_tdata(frval1),
	.s_axis_a_tvalid(fdivstrobe),
	.s_axis_b_tdata(frval2),
	.s_axis_b_tvalid(fdivstrobe),
	.aclk(clock),
	.m_axis_result_tdata(fdivresult),
	.m_axis_result_tvalid(fdivresultvalid) );

fp_i2f floati2f(
	.s_axis_a_tdata(frval1), // Integer source
	.s_axis_a_tvalid(fi2fstrobe),
	.aclk(clock),
	.m_axis_result_tdata(fi2fresult),
	.m_axis_result_tvalid(fi2fresultvalid) );

fp_ui2f floatui2f(
	.s_axis_a_tdata(frval1), // Integer source
	.s_axis_a_tvalid(fui2fstrobe),
	.aclk(clock),
	.m_axis_result_tdata(fui2fresult),
	.m_axis_result_tvalid(fui2fresultvalid) );

fp_f2i floatf2i(
	.s_axis_a_tdata(frval1), // Float source
	.s_axis_a_tvalid(ff2istrobe),
	.aclk(clock),
	.m_axis_result_tdata(ff2iresult),
	.m_axis_result_tvalid(ff2iresultvalid) );

// NOTE: Sharing same logic with f2i here, ignoring sign bit instead
fp_f2i floatf2ui(
	.s_axis_a_tdata({1'b0,frval1[30:0]}), // abs(A) (float register is source)
	.s_axis_a_tvalid(ff2uistrobe),
	.aclk(clock),
	.m_axis_result_tdata(ff2uiresult),
	.m_axis_result_tvalid(ff2uiresultvalid) );
	
fp_sqrt floatsqrt(
	.s_axis_a_tdata({1'b0,frval1[30:0]}), // abs(A) (float register is source)
	.s_axis_a_tvalid(fsqrtstrobe),
	.aclk(clock),
	.m_axis_result_tdata(fsqrtresult),
	.m_axis_result_tvalid(fsqrtresultvalid) );

fp_eq floateq(
	.s_axis_a_tdata(frval1),
	.s_axis_a_tvalid(feqstrobe),
	.s_axis_b_tdata(frval2),
	.s_axis_b_tvalid(feqstrobe),
	.aclk(clock),
	.m_axis_result_tdata(feqresult),
	.m_axis_result_tvalid(feqresultvalid) );

fp_lt floatlt(
	.s_axis_a_tdata(frval1),
	.s_axis_a_tvalid(fltstrobe),
	.s_axis_b_tdata(frval2),
	.s_axis_b_tvalid(fltstrobe),
	.aclk(clock),
	.m_axis_result_tdata(fltresult),
	.m_axis_result_tvalid(fltresultvalid) );

fp_le floatle(
	.s_axis_a_tdata(frval1),
	.s_axis_a_tvalid(flestrobe),
	.s_axis_b_tdata(frval2),
	.s_axis_b_tvalid(flestrobe),
	.aclk(clock),
	.m_axis_result_tdata(fleresult),
	.m_axis_result_tvalid(fleresultvalid) );

endmodule
