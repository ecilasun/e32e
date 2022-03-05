`timescale 1ns / 1ps

import axi_pkg::*;

module uncacheddevicechain(
	input wire aclk,
	input wire aresetn,
	input wire uartbaseclock,
	output wire uart_rxd_out,
	input wire uart_txd_in,
	axi_if.slave axi4if,
	output wire [3:0] irq);

// ------------------------------------------------------------------------------------
// Memory mapped hardware
// ------------------------------------------------------------------------------------

// uart @20000000
wire validwaddr_uart = axi4if.awaddr>=32'h20000000 && axi4if.awaddr<32'h20001000;
wire validraddr_uart = axi4if.araddr>=32'h20000000 && axi4if.araddr<32'h20001000;
axi_if uartif();
wire uartrcvempty;
axi4uart UART(
	.aclk(aclk),
	.aresetn(aresetn),
	.s_axi(uartif),
	.uartbaseclock(uartbaseclock),
	.uart_rxd_out(uart_rxd_out),
	.uart_txd_in(uart_txd_in),
	.uartrcvempty(uartrcvempty) );

// spimaster @20001000
/*wire validwaddr_spi = axi4if.awaddr>=32'h20001000 && axi4if.awaddr<32'h20002000;
wire validraddr_spi = axi4if.araddr>=32'h20001000 && axi4if.araddr<32'h20002000;
axi_if spiif();
axi4spi spimaster(
	.aclk(aclk),
	.aresetn(aresetn),
	.axi4if(spiif),
	.clocks(clocks),
	.wires(wires) );*/

// ps2 keyboard @20002000
/*wire validwaddr_ps2 = axi4if.awaddr>=32'h20002000 && axi4if.awaddr<32'h20003000;
wire validraddr_ps2 = axi4if.araddr>=32'h20002000 && axi4if.araddr<32'h20003000;
uart_txd_in ps2if();
wire ps2fifoempty;
axi4ps2keyboard ps2keyboard(
	.aclk(aclk),
	.aresetn(aresetn),
	.axi4if(ps2if),
	.clocks(clocks),
	.wires(wires),
	.ps2fifoempty(ps2fifoempty) );*/

// fpu @20003000
/*wire validwaddr_fpu = axi4if.awaddr>=32'h20003000 && axi4if.awaddr<32'h20004000;
wire validraddr_fpu = axi4if.araddr>=32'h20003000 && axi4if.araddr<32'h20004000;
axi_if fpuif();
axi4fpu floatingpointunit(
	.aclk(aclk),
	.aresetn(aresetn),
	.axi4if(fpuif) );*/

// buttons @20004000
/*wire validwaddr_button = axi4if.awaddr>=32'h20004000 && axi4if.awaddr<32'h20005000;
wire validraddr_button = axi4if.araddr>=32'h20004000 && axi4if.araddr<32'h20005000;
axi_if buttonif();
wire buttonfifoempty;
axi4buttons devicebuttons(
	.aclk(aclk),
	.aresetn(aresetn),
	.axi4if(buttonif),
	.clocks(clocks),
	.wires(wires),
	.buttonfifoempty(buttonfifoempty) );*/


// mailbox @20005000
wire validwaddr_mailbox = axi4if.awaddr>=32'h20005000 && axi4if.awaddr<32'h20006000;
wire validraddr_mailbox = axi4if.araddr>=32'h20005000 && axi4if.araddr<32'h20006000;
axi_if mailboxif();
axi4mailbox mailbox(
	.aclk(aclk),
	.aresetn(aresetn),
	.s_axi(mailboxif) );

// ------------------------------------------------------------------------------------
// interrupt setup
// ------------------------------------------------------------------------------------

// TODO: Also add wires.spi_cd != oldcd as an interrupt trigger here, preferably debounced
//assign irq = {1'b0, ~ps2fifoempty, ~buttonfifoempty, ~uartrcvempty};
assign irq = {1'b0, 1'b0, 1'b0, ~uartrcvempty};

// ------------------------------------------------------------------------------------
// write router
// ------------------------------------------------------------------------------------

wire [31:0] waddr = {3'b000, axi4if.awaddr[28:0]};

always_comb begin
	uartif.awaddr = validwaddr_uart ? waddr : 32'dz;
	uartif.awvalid = validwaddr_uart ? axi4if.awvalid : 1'b0;
	uartif.awlen = validwaddr_uart ? axi4if.awlen : 0;
	uartif.awsize = validwaddr_uart ? axi4if.awsize : 0;
	uartif.awburst = validwaddr_uart ? axi4if.awburst : 0;
	uartif.wdata = validwaddr_uart ? axi4if.wdata : 32'dz;
	uartif.wstrb = validwaddr_uart ? axi4if.wstrb : 4'h0;
	uartif.wvalid = validwaddr_uart ? axi4if.wvalid : 1'b0;
	uartif.bready = validwaddr_uart ? axi4if.bready : 1'b0;
	uartif.wlast = validwaddr_uart ? axi4if.wlast : 1'b0;

	mailboxif.awaddr = validwaddr_mailbox ? waddr : 32'dz;
	mailboxif.awvalid = validwaddr_mailbox ? axi4if.awvalid : 1'b0;
	mailboxif.awlen = validwaddr_mailbox ? axi4if.awlen : 0;
	mailboxif.awsize = validwaddr_mailbox ? axi4if.awsize : 0;
	mailboxif.awburst = validwaddr_mailbox ? axi4if.awburst : 0;
	mailboxif.wdata = validwaddr_mailbox ? axi4if.wdata : 32'dz;
	mailboxif.wstrb = validwaddr_mailbox ? axi4if.wstrb : 4'h0;
	mailboxif.wvalid = validwaddr_mailbox ? axi4if.wvalid : 1'b0;
	mailboxif.bready = validwaddr_mailbox ? axi4if.bready : 1'b0;
	mailboxif.wlast = validwaddr_mailbox ? axi4if.wlast : 1'b0;

	/*spiif.awaddr = validwaddr_spi ? waddr : 32'dz;
	spiif.awvalid = validwaddr_spi ? axi4if.awvalid : 1'b0;
	spiif.wdata = validwaddr_spi ? axi4if.wdata : 32'dz;
	spiif.wstrb = validwaddr_spi ? axi4if.wstrb : 4'h0;
	spiif.wvalid = validwaddr_spi ? axi4if.wvalid : 1'b0;
	spiif.bready = validwaddr_spi ? axi4if.bready : 1'b0;
	spiif.wlast = validwaddr_spi ? axi4if.wlast : 1'b0;*/

	/*ps2if.awaddr = validwaddr_ps2 ? waddr : 32'dz;
	ps2if.awvalid = validwaddr_ps2 ? axi4if.awvalid : 1'b0;
	ps2if.wdata = validwaddr_ps2 ? axi4if.wdata : 32'dz;
	ps2if.wstrb = validwaddr_ps2 ? axi4if.wstrb : 4'h0;
	ps2if.wvalid = validwaddr_ps2 ? axi4if.wvalid : 1'b0;
	ps2if.bready = validwaddr_ps2 ? axi4if.bready : 1'b0;
	ps2if.wlast = validwaddr_ps2 ? axi4if.wlast : 1'b0;*/

	/*fpuif.awaddr = validwaddr_fpu ? waddr : 32'dz;
	fpuif.awvalid = validwaddr_fpu ? axi4if.awvalid : 1'b0;
	fpuif.wdata = validwaddr_fpu ? axi4if.wdata : 32'dz;
	fpuif.wstrb = validwaddr_fpu ? axi4if.wstrb : 4'h0;
	fpuif.wvalid = validwaddr_fpu ? axi4if.wvalid : 1'b0;
	fpuif.bready = validwaddr_fpu ? axi4if.bready : 1'b0;
	fpuif.wlast = validwaddr_fpu ? axi4if.wlast : 1'b0;*/

	/*ddr3if.awaddr = validwaddr_ddr3 ? waddr : 32'dz;
	ddr3if.awvalid = validwaddr_ddr3 ? axi4if.awvalid : 1'b0;
	ddr3if.wdata = validwaddr_ddr3 ? axi4if.wdata : 32'dz;
	ddr3if.wstrb = validwaddr_ddr3 ? axi4if.wstrb : 4'h0;
	ddr3if.wvalid = validwaddr_ddr3 ? axi4if.wvalid : 1'b0;
	ddr3if.bready = validwaddr_ddr3 ? axi4if.bready : 1'b0;
	ddr3if.wlast = validwaddr_ddr3 ? axi4if.wlast : 1'b0;*/

	/*gpuif.awaddr = validwaddr_gpu ? waddr : 32'dz;
	gpuif.awvalid = validwaddr_gpu ? axi4if.awvalid : 1'b0;
	gpuif.wdata = validwaddr_gpu ? axi4if.wdata : 32'dz;
	gpuif.wstrb = validwaddr_gpu ? axi4if.wstrb : 4'h0;
	gpuif.wvalid = validwaddr_gpu ? axi4if.wvalid : 1'b0;
	gpuif.bready = validwaddr_gpu ? axi4if.bready : 1'b0;
	gpuif.wlast = validwaddr_gpu ? axi4if.wlast : 1'b0;*/

	/*buttonif.awaddr = validwaddr_button ? waddr : 32'dz;
	buttonif.awvalid = validwaddr_button ? axi4if.awvalid : 1'b0;
	buttonif.wdata = validwaddr_button ? axi4if.wdata : 32'dz;
	buttonif.wstrb = validwaddr_button ? axi4if.wstrb : 4'h0;
	buttonif.wvalid = validwaddr_button ? axi4if.wvalid : 1'b0;
	buttonif.bready = validwaddr_button ? axi4if.bready : 1'b0;
	buttonif.wlast = validwaddr_button ? axi4if.wlast : 1'b0;*/

	if (validwaddr_uart) begin
		axi4if.awready = uartif.awready;
		axi4if.bresp = uartif.bresp;
		axi4if.bvalid = uartif.bvalid;
		axi4if.wready = uartif.wready;
	end else begin/*if (validwaddr_mailbox) begin*/
		axi4if.awready = mailboxif.awready;
		axi4if.bresp = mailboxif.bresp;
		axi4if.bvalid = mailboxif.bvalid;
		axi4if.wready = mailboxif.wready;
	/*end else if (validwaddr_spi) begin
		axi4if.awready = spiif.awready;
		axi4if.bresp = spiif.bresp;
		axi4if.bvalid = spiif.bvalid;
		axi4if.wready = spiif.wready;*/
	/*end else if (validwaddr_ps2) begin
		axi4if.awready = ps2if.awready;
		axi4if.bresp = ps2if.bresp;
		axi4if.bvalid = ps2if.bvalid;
		axi4if.wready = ps2if.wready;*/
	/*end else if (validwaddr_fpu) begin
		axi4if.awready = fpuif.awready;
		axi4if.bresp = fpuif.bresp;
		axi4if.bvalid = fpuif.bvalid;
		axi4if.wready = fpuif.wready;*/
	/*end else if (validwaddr_bram) begin
		axi4if.awready = bramif.awready;
		axi4if.bresp = bramif.bresp;
		axi4if.bvalid = bramif.bvalid;
		axi4if.wready = bramif.wready;*/
	/*end else if (validwaddr_ddr3) begin
		axi4if.awready = ddr3if.awready;
		axi4if.bresp = ddr3if.bresp;
		axi4if.bvalid = ddr3if.bvalid;
		axi4if.wready = ddr3if.wready;*/
	/*end else if (validwaddr_gpu) begin
		axi4if.awready = gpuif.awready;
		axi4if.bresp = gpuif.bresp;
		axi4if.bvalid = gpuif.bvalid;
		axi4if.wready = gpuif.wready;*/
	/*end else begin //if (validwaddr_button) begin
		axi4if.awready = buttonif.awready;
		axi4if.bresp = buttonif.bresp;
		axi4if.bvalid = buttonif.bvalid;
		axi4if.wready = buttonif.wready;*/
	end
end

// ------------------------------------------------------------------------------------
// read router
// ------------------------------------------------------------------------------------

wire [31:0] raddr = {3'b000, axi4if.araddr[28:0]};

always_comb begin

	uartif.araddr = validraddr_uart ? raddr : 32'dz;
	uartif.arlen = validraddr_uart ? axi4if.arlen : 0;
	uartif.arsize = validraddr_uart ? axi4if.arsize : 0;
	uartif.arburst = validraddr_uart ? axi4if.arburst : 0;
	uartif.arvalid = validraddr_uart ? axi4if.arvalid : 1'b0;
	uartif.rready = validraddr_uart ? axi4if.rready : 1'b0;

	mailboxif.araddr = validraddr_mailbox ? raddr : 32'dz;
	mailboxif.arlen = validraddr_mailbox ? axi4if.arlen : 0;
	mailboxif.arsize = validraddr_mailbox ? axi4if.arsize : 0;
	mailboxif.arburst = validraddr_mailbox ? axi4if.arburst : 0;
	mailboxif.arvalid = validraddr_mailbox ? axi4if.arvalid : 1'b0;
	mailboxif.rready = validraddr_mailbox ? axi4if.rready : 1'b0;

	/*mailboxif.araddr = validraddr_mailbox ? raddr : 32'dz;
	mailboxif.arvalid = validraddr_mailbox ? axi4if.arvalid : 1'b0;
	mailboxif.rready = validraddr_mailbox ? axi4if.rready : 1'b0;*/

	/*spiif.araddr = validraddr_spi ? raddr : 32'dz;
	spiif.arvalid = validraddr_spi ? axi4if.arvalid : 1'b0;
	spiif.rready = validraddr_spi ? axi4if.rready : 1'b0;*/

	/*ps2if.araddr = validraddr_ps2 ? raddr : 32'dz;
	ps2if.arvalid = validraddr_ps2 ? axi4if.arvalid : 1'b0;
	ps2if.rready = validraddr_ps2 ? axi4if.rready : 1'b0;*/

	/*fpuif.araddr = validraddr_fpu ? raddr : 32'dz;
	fpuif.arvalid = validraddr_fpu ? axi4if.arvalid : 1'b0;
	fpuif.rready = validraddr_fpu ? axi4if.rready : 1'b0;*/

	/*ddr3if.araddr = validraddr_ddr3 ? raddr : 32'dz;
	ddr3if.arvalid = validraddr_ddr3 ? axi4if.arvalid : 1'b0;
	ddr3if.rready = validraddr_ddr3 ? axi4if.rready : 1'b0;*/

	/*gpuif.araddr = validraddr_gpu ? raddr : 32'dz;
	gpuif.arvalid = validraddr_gpu ? axi4if.arvalid : 1'b0;
	gpuif.rready = validraddr_gpu ? axi4if.rready : 1'b0;*/

	/*buttonif.araddr = validraddr_button ? raddr : 32'dz;
	buttonif.arvalid = validraddr_button ? axi4if.arvalid : 1'b0;
	buttonif.rready = validraddr_button ? axi4if.rready : 1'b0;*/

	if (validraddr_uart) begin
		axi4if.arready = uartif.arready;
		axi4if.rdata = uartif.rdata;
		axi4if.rresp = uartif.rresp;
		axi4if.rvalid = uartif.rvalid;
		axi4if.rlast = uartif.rlast;
	end else begin /*if (validraddr_mailbox) begin*/
		axi4if.arready = mailboxif.arready;
		axi4if.rdata = mailboxif.rdata;
		axi4if.rresp = mailboxif.rresp;
		axi4if.rvalid = mailboxif.rvalid;
		axi4if.rlast = mailboxif.rlast;
	/*end else if (validraddr_spi) begin
		axi4if.arready = spiif.arready;
		axi4if.rdata = spiif.rdata;
		axi4if.rresp = spiif.rresp;
		axi4if.rvalid = spiif.rvalid;
		axi4if.rlast = spiif.rlast;*/
	/*end else if (validraddr_ps2) begin
		axi4if.arready = ps2if.arready;
		axi4if.rdata = ps2if.rdata;
		axi4if.rresp = ps2if.rresp;
		axi4if.rvalid = ps2if.rvalid;
		axi4if.rlast = ps2if.rlast;*/
	/*end else if (validraddr_fpu) begin
		axi4if.arready = fpuif.arready;
		axi4if.rdata = fpuif.rdata;
		axi4if.rresp = fpuif.rresp;
		axi4if.rvalid = fpuif.rvalid;
		axi4if.rlast = fpuif.rlast;*/
	/*end else if (validraddr_bram) begin
		axi4if.arready = bramif.arready;
		axi4if.rdata = bramif.rdata;
		axi4if.rresp = bramif.rresp;
		axi4if.rvalid = bramif.rvalid;
		axi4if.rlast = bramif.rlast;*/
	/*end else if (validraddr_ddr3) begin
		axi4if.arready = ddr3if.arready;
		axi4if.rdata = ddr3if.rdata;
		axi4if.rresp = ddr3if.rresp;
		axi4if.rvalid = ddr3if.rvalid;
		axi4if.rlast = ddr3if.rlast;*/
	/*end else if (validraddr_gpu) begin
		axi4if.arready = gpuif.arready;
		axi4if.rdata = gpuif.rdata;
		axi4if.rresp = gpuif.rresp;
		axi4if.rvalid = gpuif.rvalid;
		axi4if.rlast = gpuif.rlast;*/
	/*end else begin //if (validraddr_button) begin
		axi4if.arready = buttonif.arready;
		axi4if.rdata = buttonif.rdata;
		axi4if.rresp = buttonif.rresp;
		axi4if.rvalid = buttonif.rvalid;
		axi4if.rlast = buttonif.rlast;*/
	end
end

endmodule
