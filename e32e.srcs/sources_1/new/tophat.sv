`timescale 1ns / 1ps

import axi_pkg::*;

module tophat(
	input wire sys_clock,
	output wire uart_rxd_out,
	input wire uart_txd_in );

// ----------------------------------------------------------------------------
// Simplified diagram:
// CPU -> (Custom Bus) -> CacheUnit(I$/D$) -> (Custom Bus) --> CMemController --> (AXI4) -> Memory
//                                         \-> (Custom Bus) -> UCMemController -> (AXI4) -> Devices
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// Clock / reset generator
// ----------------------------------------------------------------------------

wire aclk, wallclock, uartbaseclock, aresetn;
clockandreset ClockAndResetGen(
	.sys_clock_i(sys_clock),
	.busclock(aclk),
	.wallclock(wallclock),
	.uartbaseclock(uartbaseclock),
	//.pixelclock(pixelclock),
	//.videoclock(videoclock),
	//.clk_sys_i(clk_sys_i),
	//.clk_ref_i(clk_ref_i),
	.selfresetn(aresetn) );

// ----------------------------------------------------------------------------
// wires
// ----------------------------------------------------------------------------

wire ifetch;					// I$/D$ select
addr_t addr;					// Memory address
wire ren;						// Read enable
wire [3:0] wstrb;				// Write strobe
wire [31:0] din;				// Input to CPU
wire [31:0] dout;				// Output from CPU
wire wready, rready;			// Cache r/w state

wire rdone, wdone;				// Memory controller r/w state

wire [31:0] cacheaddress;
wire data_t cachelinein[0:15];
wire data_t cachelineout[0:15];
wire memwritestrobe, memreadstrobe;

axi_if a4buscached();
axi_if a4busuncached();

// ----------------------------------------------------------------------------
// cpu
// ----------------------------------------------------------------------------

rv32cpu #(.RESETVECTOR(32'h80000000), .HARTID(0)) HART0 (
	.aclk(aclk),
	.aresetn(aresetn),
	.addr(addr),
	.wstrb(wstrb),
	.ren(ren),
	.ifetch(ifetch),
	.din(din),
	.dout(dout),
	.wready(wready),
	.rready(rready) );

// ----------------------------------------------------------------------------
// device select
// ----------------------------------------------------------------------------

// bit0: unused
// bit1: uncached when set, otherwise cached acces
// bit2: unused
// bit3: internal memory when set, otherwise external memory
// we land on uncached bus when top four address bits are 0010 (uncached)
// in this case we only have one device there, which is the UART
// regular memory addresses in BRAM start with 1000 (internal, cached), DDR3 addresses with 0000 (external, cached)
wire isuncachedbus = (addr[31:28] == 4'h2) ? 1'b1 : 1'b0;

// ----------------------------------------------------------------------------
// cached/uncached memory access
// ----------------------------------------------------------------------------

wire [31:0] ucaddrs;
wire [31:0] ucdout;
wire [31:0] ucdin;
wire [3:0] ucwstrb;
wire ucwritedone;
wire ucreaddone;
wire ucre;

systemcache HART0Cache(
	.aclk(aclk),
	.aresetn(aresetn),
	.uncached(isuncachedbus),
	// From CPU
	.ifetch(ifetch),
	.addr(addr),
	.din(dout),
	.dout(din),
	.wstrb(wstrb),
	.ren(ren),
	.wready(wready),
	.rready(rready),
	// To cached memory controller (when uncached is low)
	.cacheaddress(cacheaddress),
	.cachedin(cachelineout),
	.cachedout(cachelinein),
	.memwritestrobe(memwritestrobe),
	.memreadstrobe(memreadstrobe),
	.wdone(wdone),
	.rdone(rdone),
	// Uncached access channel
	.ucaddrs(ucaddrs),
	.ucdout(ucdout),
	.ucwstrb(ucwstrb),
	.ucwritedone(ucwritedone),
	.ucreaddone(ucreaddone),
	.ucdin(ucdin),
	.ucre(ucre) );

// ----------------------------------------------------------------------------
// cached/uncached memory controllers
// ----------------------------------------------------------------------------

cachedmemorycontroller CMEMCTL(
	.aclk(aclk),
	.areset_n(aresetn),
	// From cache
	.addr(cacheaddress),
	.din(cachelinein),
	.dout(cachelineout),
	.start_read(memreadstrobe),
	.start_write(memwritestrobe),
	.wdone(wdone),
	.rdone(rdone),
	// To memory
	.m_axi(a4buscached) );

// For now we have only one device, so we directly wire it here
uncachedmemorycontroller UCMEMCTL(
	.aclk(aclk),
	.areset_n(aresetn),
	// From cache
	.addr(ucaddrs),
	.din(ucdout),
	.dout(ucdin),
	.re(ucre),
	.wstrb(ucwstrb),
	.wdone(ucwritedone),
	.rdone(ucreaddone),
	// To memory mapped devices
	.m_axi(a4busuncached) );

// ----------------------------------------------------------------------------
// memory and other memory mapped devices
// ----------------------------------------------------------------------------

// TODO: AXI crossbar here from all incoming a4buscached lines to all memory modules

a4bram cachedBRAM64K(
	.aclk(aclk),
	.aresetn(aresetn),
	.s_axi(a4buscached) );

// TODO: AXI crossbar here from all incoming a4busuncached lines to all devices

wire uartrcvempty; // TODO: to drive interrupts with
axi4uart UART(
	.aclk(aclk),
	.aresetn(aresetn),
	.axi4if(a4busuncached),
	.uartbaseclock(uartbaseclock),
	.uart_rxd_out(uart_rxd_out),
	.uart_txd_in(uart_txd_in),
	.uartrcvempty(uartrcvempty) );

endmodule
