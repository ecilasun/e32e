`timescale 1ns / 1ps

module topsim( );

wire uart_txd_in = 1'b1;
//wire uart_rxd_out;

logic board_clock = 0;
always #5 board_clock = ~board_clock;

// DDR3 simulation model
/*wire ddr3_reset_n;
wire [0:0]   ddr3_cke;
wire [0:0]   ddr3_ck_p; 
wire [0:0]   ddr3_ck_n;
wire ddr3_ras_n; 
wire ddr3_cas_n;
wire ddr3_we_n;
wire [2:0]   ddr3_ba;
wire [14:0]  ddr3_addr;
wire [0:0]   ddr3_odt;
wire [1:0]   ddr3_dm;
wire [1:0]   ddr3_dqs_p;
wire [1:0]   ddr3_dqs_n;
wire [15:0]  ddr3_dq;*/

/*ddr3_model ddr3simmod(
    .rst_n(ddr3_reset_n),
    .ck(ddr3_ck_p),
    .ck_n(ddr3_ck_n),
    .cke(ddr3_cke),
    .cs_n(1'b0),
    .ras_n(ddr3_ras_n),
    .cas_n(ddr3_cas_n),
    .we_n(ddr3_we_n),
    .dm_tdqs(ddr3_dm),
    .ba(ddr3_ba),
    .addr(ddr3_addr),
    .dq(ddr3_dq),
    .dqs(ddr3_dqs_p),
    .dqs_n(ddr3_dqs_n),
    .tdqs_n(), // out
    .odt(ddr3_odt) );*/

wire ps2_clk, ps2_data;
assign ps2_clk = 1'b1;

tophat tophatsiminst(
	.sys_clock(board_clock),
	.uart_rxd_out(/*uart_rxd_out*/),
	.uart_txd_in(uart_txd_in),
    .ps2_clk(ps2_clk),
    .ps2_data(ps2_data)/*,
    .ddr3_reset_n(ddr3_reset_n),
    .ddr3_cke(ddr3_cke),
    .ddr3_ck_p(ddr3_ck_p),
    .ddr3_ck_n(ddr3_ck_n),
    .ddr3_ras_n(ddr3_ras_n), 
    .ddr3_cas_n(ddr3_cas_n), 
    .ddr3_we_n(ddr3_we_n),
    .ddr3_ba(ddr3_ba),
    .ddr3_addr(ddr3_addr),
    .ddr3_odt(ddr3_odt),
    .ddr3_dm(ddr3_dm),
    .ddr3_dqs_p(ddr3_dqs_p),
    .ddr3_dqs_n(ddr3_dqs_n),
    .ddr3_dq(ddr3_dq)*/ );

endmodule
