`timescale 1ns / 1ps

interface devicewires (
	output uart_rxd_out,
	input uart_txd_in,
	input ps2_clk,
	input ps2_data,
	output spi_cs_n,
	output spi_mosi,
	input spi_miso,
	output spi_sck,
	input spi_cd,
	inout scl, sda,
	output ac_bclk,
	output ac_lrclk,
	output ac_dac_sdata,
	input ac_adc_sdata,
	output [7:0] led );

	modport def (
		output uart_rxd_out,
		input uart_txd_in,
		input ps2_clk,
		input ps2_data,
		output spi_cs_n,
		output spi_mosi,
		input spi_miso,
		output spi_sck,
		input spi_cd,
		inout scl,
		inout sda,
		output ac_bclk,
		output ac_lrclk,
		output ac_dac_sdata,
		input ac_adc_sdata,
		output led );

endinterface
