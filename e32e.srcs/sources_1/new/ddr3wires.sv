interface ddr3devicewires (
		output ddr3_reset_n,
		output [0:0] ddr3_cke,
		output [0:0] ddr3_ck_p, 
		output [0:0] ddr3_ck_n,
		output ddr3_ras_n, 
		output ddr3_cas_n, 
		output ddr3_we_n,
		output [2:0] ddr3_ba,
		output [14:0] ddr3_addr,
		output [0:0] ddr3_odt,
		output [1:0] ddr3_dm,
		inout [1:0] ddr3_dqs_p,
		inout [1:0] ddr3_dqs_n,
		inout [15:0] ddr3_dq );

	modport def (
		output ddr3_reset_n,
		output ddr3_cke,
		output ddr3_ck_p, 
		output ddr3_ck_n,
		output ddr3_ras_n, 
		output ddr3_cas_n, 
		output ddr3_we_n,
		output ddr3_ba,
		output ddr3_addr,
		output ddr3_odt,
		output ddr3_dm,
		inout ddr3_dqs_p,
		inout ddr3_dqs_n,
		inout ddr3_dq );

endinterface