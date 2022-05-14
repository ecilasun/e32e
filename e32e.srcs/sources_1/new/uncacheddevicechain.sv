`timescale 1ns / 1ps

import axi_pkg::*;

module uncacheddevicechain(
	input wire aclk,
	input wire aresetn,
	input wire pixelclock,
	input wire videoclock,
	input wire hidclock,
	input wire uartbaseclock,
	input wire spibaseclock,
    axi_if.slave axi4if,
	gpudataoutput.def gpudata,
	output wire [11:0] irq,
	devicewires.def wires );

// ------------------------------------------------------------------------------------
// Memory mapped hardware
// ------------------------------------------------------------------------------------

logic validwaddr_mailbox = 1'b0, validraddr_mailbox = 1'b0;
logic validwaddr_uart = 1'b0, validraddr_uart = 1'b0;
logic validwaddr_spi = 1'b0, validraddr_spi = 1'b0;
logic validwaddr_ps2 = 1'b0, validraddr_ps2 = 1'b0;
logic validwaddr_leds = 1'b0, validraddr_leds = 1'b0;
//logic validwaddr_buttons = 1'b0, validraddr_buttons = 1'b0;
logic validwaddr_hart = 1'b0, validraddr_hart = 1'b0;
logic validwaddr_gpu = 1'b0, validraddr_gpu = 1'b0;
logic validwaddr_audio = 1'b0, validraddr_audio = 1'b0;

always_comb begin
	if (axi4if.awaddr[31]) begin
		validwaddr_mailbox		= (axi4if.awaddr[28:0]>=29'h0000000) && (axi4if.awaddr[28:0]<29'h0001000);
		validwaddr_uart			= (axi4if.awaddr[28:0]>=29'h0001000) && (axi4if.awaddr[28:0]<29'h0001010);
		validwaddr_spi			= (axi4if.awaddr[28:0]>=29'h0001010) && (axi4if.awaddr[28:0]<29'h0001020);
		validwaddr_ps2			= (axi4if.awaddr[28:0]>=29'h0001020) && (axi4if.awaddr[28:0]<29'h0001030);
		validwaddr_leds			= (axi4if.awaddr[28:0]>=29'h0001030) && (axi4if.awaddr[28:0]<29'h0001040);
		validwaddr_hart			= (axi4if.awaddr[28:0]>=29'h0001040) && (axi4if.awaddr[28:0]<29'h0001050);
		//validwaddr_buttons	= (axi4if.awaddr[28:0]>=29'h0001050) && (axi4if.awaddr[28:0]<29'h0001060);
		validwaddr_gpu			= (axi4if.awaddr[28:0]>=29'h1000000) && (axi4if.awaddr[28:0]<29'h1080000);
		validwaddr_audio		= (axi4if.awaddr[28:0]>=29'h2000000) && (axi4if.awaddr[28:0]<29'h2000010);
	end else begin
		validwaddr_mailbox		= 1'b0;
		validwaddr_uart			= 1'b0;
		validwaddr_spi			= 1'b0;
		validwaddr_ps2			= 1'b0;
		validwaddr_leds			= 1'b0;
		//validwaddr_buttons	= 1'b0;
		validwaddr_hart			= 1'b0;
		validwaddr_gpu			= 1'b0;
		validwaddr_audio		= 1'b0;
	end
end

always_comb begin
	if (axi4if.araddr[31]) begin
		validraddr_mailbox		= (axi4if.araddr[28:0]>=29'h0000000) && (axi4if.araddr[28:0]<29'h0001000);
		validraddr_uart			= (axi4if.araddr[28:0]>=29'h0001000) && (axi4if.araddr[28:0]<29'h0001010);
		validraddr_spi			= (axi4if.araddr[28:0]>=29'h0001010) && (axi4if.araddr[28:0]<29'h0001020);
		validraddr_ps2			= (axi4if.araddr[28:0]>=29'h0001020) && (axi4if.araddr[28:0]<29'h0001030);
		validraddr_leds			= (axi4if.araddr[28:0]>=29'h0001030) && (axi4if.araddr[28:0]<29'h0001040);
		validraddr_hart			= (axi4if.araddr[28:0]>=29'h0001040) && (axi4if.araddr[28:0]<29'h0001050);
		//validraddr_buttons	= (axi4if.araddr[28:0]>=29'h0001050) && (axi4if.araddr[28:0]<29'h0001060);
		validraddr_gpu			= (axi4if.araddr[28:0]>=29'h1000000) && (axi4if.araddr[28:0]<29'h1080000);
		validraddr_audio		= (axi4if.araddr[28:0]>=29'h2000000) && (axi4if.araddr[28:0]<29'h2000010);
	end else begin
		validraddr_mailbox		= 1'b0;
		validraddr_uart			= 1'b0;
		validraddr_spi			= 1'b0;
		validraddr_ps2			= 1'b0;
		//validraddr_buttons	= 1'b0;
		validraddr_leds			= 1'b0;
		validraddr_hart			= 1'b0;
		validraddr_gpu			= 1'b0;
		validraddr_audio		= 1'b0;
	end
end

axi_if mailboxif();
axi4mailbox mailbox(
	.aclk(aclk),
	.aresetn(aresetn),
	.s_axi(mailboxif) );

axi_if uartif();
wire uartrcvempty;
axi4uart UART(
	.aclk(aclk),
	.aresetn(aresetn),
	.s_axi(uartif),
	.uartbaseclock(uartbaseclock),
	.uart_rxd_out(wires.uart_rxd_out),
	.uart_txd_in(wires.uart_txd_in),
	.uartrcvempty(uartrcvempty) );

axi_if spiif();
axi4spi spimaster(
	.aclk(aclk),
	.spibaseclock(spibaseclock),
	.aresetn(aresetn),
	.spi_cs_n(wires.spi_cs_n),
	.spi_mosi(wires.spi_mosi),
	.spi_miso(wires.spi_miso),
	.spi_sck(wires.spi_sck),
	.s_axi(spiif) );

axi_if ps2if();
wire ps2fifoempty;
axi4ps2keyboard ps2keyboard(
	.aclk(aclk),
	.hidclock(hidclock),
	.aresetn(aresetn),
    .ps2_clk(wires.ps2_clk),
    .ps2_data(wires.ps2_data),
	.ps2fifoempty(ps2fifoempty),
	.s_axi(ps2if) );

wire [15:0] hirq;
axi_if hartif();
axi4hartirq hartirq(
	.aclk(aclk),
	.aresetn(aresetn),
	.s_axi(hartif),
	.hirq(hirq) );

axi_if ledif();
axi4ledctl ledctl(
	.aclk(aclk),
	.aresetn(aresetn),
	.s_axi(ledif),
	.led(wires.led) );

/*
axi_if buttonif();
wire buttonfifoempty;
axi4buttons devicebuttons(
	.aclk(aclk),
	.aresetn(aresetn),
	.s_axi(buttonif),
	.clocks(clocks),
	.wires(wires),
	.buttonfifoempty(buttonfifoempty) );*/

axi_if gpuif();
axi4gpu GPU(
	.aclk(aclk),
	.aresetn(aresetn),
	.pixelclock(pixelclock),
	.videoclock(videoclock),
	.s_axi(gpuif),
	.gpudata(gpudata) );

axi_if audioif();
a4i2saudio APU(
	.aclk(aclk),
	.aresetn(aresetn),
	.hidclock(hidclock),
	.s_axi(audioif),
    .scl(scl),
    .sda(sda),
    .ac_bclk(wires.ac_bclk),
    .ac_lrclk(wires.ac_lrclk),
    .ac_dac_sdata(wires.ac_dac_sdata),
    .ac_adc_sdata(wires.ac_adc_sdata) );

// ------------------------------------------------------------------------------------
// interrupt setup
// ------------------------------------------------------------------------------------

// TODO: Also add wires.spi_cd != oldcd as an interrupt trigger here, preferably debounced
// Top 8 bits are used to wake up the corresponding HART
// Writing one to byte pointer 80001050[hartid] will hold the IRQ high
// Writing zero to the same address by the responder HART (using its own HARTID as index) in the ISR will stop the IRQ
// PS2 fifo empty is used to detect if there are any pending PS/2 keyboard bytes (responder has to drain all data)
// UART rcv empty are used to detect if there are waiting bytes in UART buffer (responder has to drain all data)
// Unused bits are reserved for future hardware
assign irq = {hirq[7:0], 1'b0, ~ps2fifoempty, 1'b0, ~uartrcvempty};

// ------------------------------------------------------------------------------------
// Uncached device write router
// ------------------------------------------------------------------------------------

wire [31:0] waddr = {3'b000, axi4if.awaddr[28:0]};

always_comb begin
	uartif.awaddr = validwaddr_uart ? waddr : 32'd0;
	uartif.awvalid = validwaddr_uart ? axi4if.awvalid : 1'b0;
	uartif.awlen = validwaddr_uart ? axi4if.awlen : 0;
	uartif.awsize = validwaddr_uart ? axi4if.awsize : 0;
	uartif.awburst = validwaddr_uart ? axi4if.awburst : 0;
	uartif.wdata = validwaddr_uart ? axi4if.wdata : 0;
	uartif.wstrb = validwaddr_uart ? axi4if.wstrb : 'd0;
	uartif.wvalid = validwaddr_uart ? axi4if.wvalid : 1'b0;
	uartif.bready = validwaddr_uart ? axi4if.bready : 1'b0;
	uartif.wlast = validwaddr_uart ? axi4if.wlast : 1'b0;

	mailboxif.awaddr = validwaddr_mailbox ? waddr : 32'd0;
	mailboxif.awvalid = validwaddr_mailbox ? axi4if.awvalid : 1'b0;
	mailboxif.awlen = validwaddr_mailbox ? axi4if.awlen : 0;
	mailboxif.awsize = validwaddr_mailbox ? axi4if.awsize : 0;
	mailboxif.awburst = validwaddr_mailbox ? axi4if.awburst : 0;
	mailboxif.wdata = validwaddr_mailbox ? axi4if.wdata : 0;
	mailboxif.wstrb = validwaddr_mailbox ? axi4if.wstrb : 'd0;
	mailboxif.wvalid = validwaddr_mailbox ? axi4if.wvalid : 1'b0;
	mailboxif.bready = validwaddr_mailbox ? axi4if.bready : 1'b0;
	mailboxif.wlast = validwaddr_mailbox ? axi4if.wlast : 1'b0;

	spiif.awaddr = validwaddr_spi ? waddr : 32'd0;
	spiif.awvalid = validwaddr_spi ? axi4if.awvalid : 1'b0;
	spiif.awlen = validwaddr_spi ? axi4if.awlen : 0;
	spiif.awsize = validwaddr_spi ? axi4if.awsize : 0;
	spiif.awburst = validwaddr_spi ? axi4if.awburst : 0;
	spiif.wdata = validwaddr_spi ? axi4if.wdata : 0;
	spiif.wstrb = validwaddr_spi ? axi4if.wstrb : 4'h0;
	spiif.wvalid = validwaddr_spi ? axi4if.wvalid : 1'b0;
	spiif.bready = validwaddr_spi ? axi4if.bready : 1'b0;
	spiif.wlast = validwaddr_spi ? axi4if.wlast : 1'b0;

	ps2if.awaddr = validwaddr_ps2 ? waddr : 32'd0;
	ps2if.awvalid = validwaddr_ps2 ? axi4if.awvalid : 1'b0;
	ps2if.awlen = validwaddr_ps2 ? axi4if.awlen : 0;
	ps2if.awsize = validwaddr_ps2 ? axi4if.awsize : 0;
	ps2if.awburst = validwaddr_ps2 ? axi4if.awburst : 0;
	ps2if.wdata = validwaddr_ps2 ? axi4if.wdata : 0;
	ps2if.wstrb = validwaddr_ps2 ? axi4if.wstrb : 'd0;
	ps2if.wvalid = validwaddr_ps2 ? axi4if.wvalid : 1'b0;
	ps2if.bready = validwaddr_ps2 ? axi4if.bready : 1'b0;
	ps2if.wlast = validwaddr_ps2 ? axi4if.wlast : 1'b0;

	hartif.awaddr = validwaddr_hart ? waddr : 32'd0;
	hartif.awvalid = validwaddr_hart ? axi4if.awvalid : 1'b0;
	hartif.awlen = validwaddr_hart ? axi4if.awlen : 0;
	hartif.awsize = validwaddr_hart ? axi4if.awsize : 0;
	hartif.awburst = validwaddr_hart ? axi4if.awburst : 0;
	hartif.wdata = validwaddr_hart ? axi4if.wdata : 0;
	hartif.wstrb = validwaddr_hart ? axi4if.wstrb : 'd0;
	hartif.wvalid = validwaddr_hart ? axi4if.wvalid : 1'b0;
	hartif.bready = validwaddr_hart ? axi4if.bready : 1'b0;
	hartif.wlast = validwaddr_hart ? axi4if.wlast : 1'b0;

	ledif.awaddr = validwaddr_leds ? waddr : 32'd0;
	ledif.awvalid = validwaddr_leds ? axi4if.awvalid : 1'b0;
	ledif.awlen = validwaddr_leds ? axi4if.awlen : 0;
	ledif.awsize = validwaddr_leds ? axi4if.awsize : 0;
	ledif.awburst = validwaddr_leds ? axi4if.awburst : 0;
	ledif.wdata = validwaddr_leds ? axi4if.wdata : 0;
	ledif.wstrb = validwaddr_leds ? axi4if.wstrb : 4'h0;
	ledif.wvalid = validwaddr_leds ? axi4if.wvalid : 1'b0;
	ledif.bready = validwaddr_leds ? axi4if.bready : 1'b0;
	ledif.wlast = validwaddr_leds ? axi4if.wlast : 1'b0;

	gpuif.awaddr = validwaddr_gpu ? waddr : 32'd0;
	gpuif.awvalid = validwaddr_gpu ? axi4if.awvalid : 1'b0;
	gpuif.awlen = validwaddr_gpu ? axi4if.awlen : 0;
	gpuif.awsize = validwaddr_gpu ? axi4if.awsize : 0;
	gpuif.awburst = validwaddr_gpu ? axi4if.awburst : 0;
	gpuif.wdata = validwaddr_gpu ? axi4if.wdata : 0;
	gpuif.wstrb = validwaddr_gpu ? axi4if.wstrb : 'd0;
	gpuif.wvalid = validwaddr_gpu ? axi4if.wvalid : 1'b0;
	gpuif.bready = validwaddr_gpu ? axi4if.bready : 1'b0;
	gpuif.wlast = validwaddr_gpu ? axi4if.wlast : 1'b0;

	/*buttonif.awaddr = validwaddr_button ? waddr : 32'd0;
	buttonif.awvalid = validwaddr_button ? axi4if.awvalid : 1'b0;
	buttonif.wdata = validwaddr_button ? axi4if.wdata : 0;
	buttonif.wstrb = validwaddr_button ? axi4if.wstrb : 4'h0;
	buttonif.wvalid = validwaddr_button ? axi4if.wvalid : 1'b0;
	buttonif.bready = validwaddr_button ? axi4if.bready : 1'b0;
	buttonif.wlast = validwaddr_button ? axi4if.wlast : 1'b0;*/

	audioif.awaddr = validwaddr_audio ? waddr : 32'd0;
	audioif.awvalid = validwaddr_audio ? axi4if.awvalid : 1'b0;
	audioif.awlen = validwaddr_audio ? axi4if.awlen : 0;
	audioif.awsize = validwaddr_audio ? axi4if.awsize : 0;
	audioif.awburst = validwaddr_audio ? axi4if.awburst : 0;
	audioif.wdata = validwaddr_audio ? axi4if.wdata : 0;
	audioif.wstrb = validwaddr_audio ? axi4if.wstrb : 'd0;
	audioif.wvalid = validwaddr_audio ? axi4if.wvalid : 1'b0;
	audioif.bready = validwaddr_audio ? axi4if.bready : 1'b0;
	audioif.wlast = validwaddr_audio ? axi4if.wlast : 1'b0;

	if (validwaddr_uart) begin
		axi4if.awready = uartif.awready;
		axi4if.bresp = uartif.bresp;
		axi4if.bvalid = uartif.bvalid;
		axi4if.wready = uartif.wready;
	end else if (validwaddr_mailbox) begin
		axi4if.awready = mailboxif.awready;
		axi4if.bresp = mailboxif.bresp;
		axi4if.bvalid = mailboxif.bvalid;
		axi4if.wready = mailboxif.wready;
	end else if (validwaddr_spi) begin
		axi4if.awready = spiif.awready;
		axi4if.bresp = spiif.bresp;
		axi4if.bvalid = spiif.bvalid;
		axi4if.wready = spiif.wready;
	end else if (validwaddr_ps2) begin
		axi4if.awready = ps2if.awready;
		axi4if.bresp = ps2if.bresp;
		axi4if.bvalid = ps2if.bvalid;
		axi4if.wready = ps2if.wready;
	end else if (validwaddr_hart) begin
		axi4if.awready = hartif.awready;
		axi4if.bresp = hartif.bresp;
		axi4if.bvalid = hartif.bvalid;
		axi4if.wready = hartif.wready;
	end else if (validwaddr_leds) begin
		axi4if.awready = ledif.awready;
		axi4if.bresp = ledif.bresp;
		axi4if.bvalid = ledif.bvalid;
		axi4if.wready = ledif.wready;
	end else if (validwaddr_gpu) begin
		axi4if.awready = gpuif.awready;
		axi4if.bresp = gpuif.bresp;
		axi4if.bvalid = gpuif.bvalid;
		axi4if.wready = gpuif.wready;
	/*end else begin //if (validwaddr_button) begin
		axi4if.awready = buttonif.awready;
		axi4if.bresp = buttonif.bresp;
		axi4if.bvalid = buttonif.bvalid;
		axi4if.wready = buttonif.wready;*/
	end else if (validwaddr_audio) begin
		axi4if.awready = audioif.awready;
		axi4if.bresp = audioif.bresp;
		axi4if.bvalid = audioif.bvalid;
		axi4if.wready = audioif.wready;
	end else begin
		axi4if.awready = 0;
		axi4if.bresp = 0;
		axi4if.bvalid = 0;
		axi4if.wready = 0;
	end
end

// ------------------------------------------------------------------------------------
// Uncached device read router
// ------------------------------------------------------------------------------------

wire [31:0] raddr = {3'b000, axi4if.araddr[28:0]};

always_comb begin

	uartif.araddr = validraddr_uart ? raddr : 32'd0;
	uartif.arlen = validraddr_uart ? axi4if.arlen : 0;
	uartif.arsize = validraddr_uart ? axi4if.arsize : 0;
	uartif.arburst = validraddr_uart ? axi4if.arburst : 0;
	uartif.arvalid = validraddr_uart ? axi4if.arvalid : 1'b0;
	uartif.rready = validraddr_uart ? axi4if.rready : 1'b0;

	mailboxif.araddr = validraddr_mailbox ? raddr : 32'd0;
	mailboxif.arlen = validraddr_mailbox ? axi4if.arlen : 0;
	mailboxif.arsize = validraddr_mailbox ? axi4if.arsize : 0;
	mailboxif.arburst = validraddr_mailbox ? axi4if.arburst : 0;
	mailboxif.arvalid = validraddr_mailbox ? axi4if.arvalid : 1'b0;
	mailboxif.rready = validraddr_mailbox ? axi4if.rready : 1'b0;

	spiif.araddr = validraddr_spi ? raddr : 32'd0;
	spiif.arlen = validraddr_spi ? axi4if.arlen : 0;
	spiif.arsize = validraddr_spi ? axi4if.arsize : 0;
	spiif.arburst = validraddr_spi ? axi4if.arburst : 0;
	spiif.arvalid = validraddr_spi ? axi4if.arvalid : 1'b0;
	spiif.rready = validraddr_spi ? axi4if.rready : 1'b0;

	ps2if.araddr = validraddr_ps2 ? raddr : 32'd0;
	ps2if.arlen = validraddr_ps2 ? axi4if.arlen : 0;
	ps2if.arsize = validraddr_ps2 ? axi4if.arsize : 0;
	ps2if.arburst = validraddr_ps2 ? axi4if.arburst : 0;
	ps2if.arvalid = validraddr_ps2 ? axi4if.arvalid : 1'b0;
	ps2if.rready = validraddr_ps2 ? axi4if.rready : 1'b0;

	hartif.araddr = validraddr_hart ? raddr : 32'd0;
	hartif.arlen = validraddr_hart ? axi4if.arlen : 0;
	hartif.arsize = validraddr_hart ? axi4if.arsize : 0;
	hartif.arburst = validraddr_hart ? axi4if.arburst : 0;
	hartif.arvalid = validraddr_hart ? axi4if.arvalid : 1'b0;
	hartif.rready = validraddr_hart ? axi4if.rready : 1'b0;

	ledif.araddr = validraddr_leds ? raddr : 32'd0;
	ledif.arlen = validraddr_leds ? axi4if.arlen : 0;
	ledif.arsize = validraddr_leds ? axi4if.arsize : 0;
	ledif.arburst = validraddr_leds ? axi4if.arburst : 0;
	ledif.arvalid = validraddr_leds ? axi4if.arvalid : 1'b0;
	ledif.rready = validraddr_leds ? axi4if.rready : 1'b0;

	gpuif.araddr = validraddr_gpu ? raddr : 32'd0;
	gpuif.arlen = validraddr_gpu ? axi4if.arlen : 0;
	gpuif.arsize = validraddr_gpu ? axi4if.arsize : 0;
	gpuif.arburst = validraddr_gpu ? axi4if.arburst : 0;
	gpuif.arvalid = validraddr_gpu ? axi4if.arvalid : 1'b0;
	gpuif.rready = validraddr_gpu ? axi4if.rready : 1'b0;

	/*buttonif.araddr = validraddr_button ? raddr : 32'd0;
	buttonif.arvalid = validraddr_button ? axi4if.arvalid : 1'b0;
	buttonif.rready = validraddr_button ? axi4if.rready : 1'b0;*/

	audioif.araddr = validraddr_audio ? raddr : 32'd0;
	audioif.arlen = validraddr_audio ? axi4if.arlen : 0;
	audioif.arsize = validraddr_audio ? axi4if.arsize : 0;
	audioif.arburst = validraddr_audio ? axi4if.arburst : 0;
	audioif.arvalid = validraddr_audio ? axi4if.arvalid : 1'b0;
	audioif.rready = validraddr_audio ? axi4if.rready : 1'b0;

	if (validraddr_uart) begin
		axi4if.arready = uartif.arready;
		axi4if.rdata = uartif.rdata;
		axi4if.rresp = uartif.rresp;
		axi4if.rvalid = uartif.rvalid;
		axi4if.rlast = uartif.rlast;
	end else if (validraddr_mailbox) begin
		axi4if.arready = mailboxif.arready;
		axi4if.rdata = mailboxif.rdata;
		axi4if.rresp = mailboxif.rresp;
		axi4if.rvalid = mailboxif.rvalid;
		axi4if.rlast = mailboxif.rlast;
	end else if (validraddr_spi) begin
		axi4if.arready = spiif.arready;
		axi4if.rdata = spiif.rdata;
		axi4if.rresp = spiif.rresp;
		axi4if.rvalid = spiif.rvalid;
		axi4if.rlast = spiif.rlast;
	end else if (validraddr_ps2) begin
		axi4if.arready = ps2if.arready;
		axi4if.rdata = ps2if.rdata;
		axi4if.rresp = ps2if.rresp;
		axi4if.rvalid = ps2if.rvalid;
		axi4if.rlast = ps2if.rlast;
	end else if (validraddr_hart) begin
		axi4if.arready = hartif.arready;
		axi4if.rdata = hartif.rdata;
		axi4if.rresp = hartif.rresp;
		axi4if.rvalid = hartif.rvalid;
		axi4if.rlast = hartif.rlast;
	end else if (validraddr_leds) begin
		axi4if.arready = ledif.arready;
		axi4if.rdata = ledif.rdata;
		axi4if.rresp = ledif.rresp;
		axi4if.rvalid = ledif.rvalid;
		axi4if.rlast = ledif.rlast;
	end else if (validraddr_gpu) begin
		axi4if.arready = gpuif.arready;
		axi4if.rdata = gpuif.rdata;
		axi4if.rresp = gpuif.rresp;
		axi4if.rvalid = gpuif.rvalid;
		axi4if.rlast = gpuif.rlast;
	/*end else begin //if (validraddr_button) begin
		axi4if.arready = buttonif.arready;
		axi4if.rdata = buttonif.rdata;
		axi4if.rresp = buttonif.rresp;
		axi4if.rvalid = buttonif.rvalid;
		axi4if.rlast = buttonif.rlast;*/
	end else if (validraddr_audio) begin
		axi4if.arready = audioif.arready;
		axi4if.rdata = audioif.rdata;
		axi4if.rresp = audioif.rresp;
		axi4if.rvalid = audioif.rvalid;
		axi4if.rlast = audioif.rlast;
	end else begin
		axi4if.arready = 0;
		axi4if.rdata = 0;
		axi4if.rresp = 0;
		axi4if.rvalid = 0;
		axi4if.rlast = 0;
	end
end

endmodule
