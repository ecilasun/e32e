`timescale 1ns / 1ps

import axi_pkg::*;

module axi4uart(
	input wire aclk,
	input wire aresetn,
	axi_if.slave m_axi,
	input wire uartbaseclock,
	output wire uart_rxd_out,
	input wire uart_txd_in,
	output wire uartrcvempty );

axi_if s_axi();

axi_clock_converter_0 AXI4ClkConvUART (
  .s_axi_aclk(aclk),
  .s_axi_aresetn(aresetn),
  .s_axi_awaddr(m_axi.awaddr),
  .s_axi_awlen(m_axi.awlen),
  .s_axi_awsize(m_axi.awsize),
  .s_axi_awburst(m_axi.awburst),
  .s_axi_awlock(1'b0),
  .s_axi_awcache(4'b0011),
  .s_axi_awprot(3'b000),
  .s_axi_awregion(4'h0),
  .s_axi_awqos(4'h0),
  .s_axi_awvalid(m_axi.awvalid),
  .s_axi_awready(m_axi.awready),
  .s_axi_wdata(m_axi.wdata),
  .s_axi_wstrb(m_axi.wstrb),
  .s_axi_wlast(m_axi.wlast),
  .s_axi_wvalid(m_axi.wvalid),
  .s_axi_wready(m_axi.wready),
  .s_axi_bresp(m_axi.bresp),
  .s_axi_bvalid(m_axi.bvalid),
  .s_axi_bready(m_axi.bready),
  .s_axi_araddr(m_axi.araddr),
  .s_axi_arlen(m_axi.arlen),
  .s_axi_arsize(m_axi.arsize),
  .s_axi_arburst(m_axi.arburst),
  .s_axi_arlock(1'b0),
  .s_axi_arcache(4'b0011),
  .s_axi_arprot(3'b000),
  .s_axi_arregion(4'h0),
  .s_axi_arqos(4'h0),
  .s_axi_arvalid(m_axi.arvalid),
  .s_axi_arready(m_axi.arready),
  .s_axi_rdata(m_axi.rdata),
  .s_axi_rresp(m_axi.rresp),
  .s_axi_rlast(m_axi.rlast),
  .s_axi_rvalid(m_axi.rvalid),
  .s_axi_rready(m_axi.rready),

  .m_axi_aclk(uartbaseclock),
  .m_axi_aresetn(aresetn),
  .m_axi_awaddr(s_axi.awaddr),
  .m_axi_awlen(s_axi.awlen),
  .m_axi_awsize(s_axi.awsize),
  .m_axi_awburst(s_axi.awburst),
  .m_axi_awlock(),
  .m_axi_awcache(),
  .m_axi_awprot(),
  .m_axi_awregion(),
  .m_axi_awqos(),
  .m_axi_awvalid(s_axi.awvalid),
  .m_axi_awready(s_axi.awready),
  .m_axi_wdata(s_axi.wdata),
  .m_axi_wstrb(s_axi.wstrb),
  .m_axi_wlast(s_axi.wlast),
  .m_axi_wvalid(s_axi.wvalid),
  .m_axi_wready(s_axi.wready),
  .m_axi_bresp(s_axi.bresp),
  .m_axi_bvalid(s_axi.bvalid),
  .m_axi_bready(s_axi.bready),
  .m_axi_araddr(s_axi.araddr),
  .m_axi_arlen(s_axi.arlen),
  .m_axi_arsize(s_axi.arsize),
  .m_axi_arburst(s_axi.arburst),
  .m_axi_arlock(),
  .m_axi_arcache(),
  .m_axi_arprot(),
  .m_axi_arregion(),
  .m_axi_arqos(),
  .m_axi_arvalid(s_axi.arvalid),
  .m_axi_arready(s_axi.arready),
  .m_axi_rdata(s_axi.rdata),
  .m_axi_rresp(s_axi.rresp),
  .m_axi_rlast(s_axi.rlast),
  .m_axi_rvalid(s_axi.rvalid),
  .m_axi_rready(s_axi.rready) );

logic [1:0] waddrstate = 2'b00;
logic [1:0] writestate = 2'b00;
logic [1:0] raddrstate = 2'b00;

//logic [31:0] writeaddress = 32'd0;
logic [7:0] din = 8'h00;
logic [3:0] we = 4'h0;

// ----------------------------------------------------------------------------
// uart transmitter
// ----------------------------------------------------------------------------

bit transmitbyte = 1'b0;
bit [7:0] datatotransmit = 8'h00;
wire uarttxbusy;

async_transmitter uart_transmit(
	.clk(uartbaseclock),
	.txd_start(transmitbyte),
	.txd_data(datatotransmit),
	.txd(uart_rxd_out),
	.txd_busy(uarttxbusy) );

// ----------------------------------------------------------------------------
// uart receiver
// ----------------------------------------------------------------------------

wire uartbyteavailable;
wire [7:0] uartbytein;

async_receiver uart_receive(
	.clk(uartbaseclock),
	.rxd(uart_txd_in),
	.rxd_data_ready(uartbyteavailable),
	.rxd_data(uartbytein),
	.rxd_idle(),
	.rxd_endofpacket() );

wire uartrcvfull, uartrcvvalid;
bit [7:0] uartrcvdin = 8'h00;
wire [7:0] uartrcvdout;
bit uartrcvre = 1'b0, uartrcvwe = 1'b0;

uartinfifo UARTIn(
	.full(uartrcvfull),
	.din(uartrcvdin),
	.wr_en(uartrcvwe),
	.clk(uartbaseclock),
	.empty(uartrcvempty),
	.dout(uartrcvdout),
	.rd_en(uartrcvre),
	.valid(uartrcvvalid),
	.rst(~aresetn) );

always @(posedge uartbaseclock) begin
	uartrcvwe <= 1'b0;
	// note: any byte that won't fit into the fifo will be dropped
	// make sure to consume them quickly on arrival!
	if (uartbyteavailable & (~uartrcvfull)) begin
		uartrcvwe <= 1'b1;
		uartrcvdin <= uartbytein;
	end
end

//volatile uint32_t *IO_UARTRX     = (volatile uint32_t* ) 0x20000000;
//volatile uint32_t *IO_UARTTX     = (volatile uint32_t* ) 0x20000004;
//volatile uint32_t *IO_UARTStatus = (volatile uint32_t* ) 0x20000008;
//volatile uint32_t *IO_UARTCtl    = (volatile uint32_t* ) 0x20000000;

// main state machine
always @(posedge uartbaseclock) begin
	if (~aresetn) begin
		s_axi.awready <= 1'b0;
	end else begin
		// write address
		case (waddrstate)
			2'b00: begin
				if (s_axi.awvalid) begin
					s_axi.awready <= 1'b1;
					//writeaddress <= s_axi.awaddr; // todo: select subdevice using some bits of address
					waddrstate <= 2'b01;
				end
			end
			default/*2'b01*/: begin
				s_axi.awready <= 1'b0;
				waddrstate <= 2'b00;
			end
		endcase
	end
end

always @(posedge uartbaseclock) begin
	if (~aresetn) begin
		s_axi.bresp <= 2'b00; // okay
		s_axi.bvalid <= 1'b0;
		s_axi.wready <= 1'b0;
	end else begin
		// write data
		we <= 4'h0;
		transmitbyte <= 1'b0;
		case (writestate)
			2'b00: begin
				if (s_axi.wvalid) begin
					case (s_axi.awaddr[3:0])
						4'h0: begin // rx data
							// Cannot write here, skip
							writestate <= 2'b01;
							s_axi.wready <= 1'b1;
						end
						4'h4: begin // tx data
							if (~uarttxbusy) begin
								transmitbyte <= 1'b1;
								datatotransmit <= s_axi.wdata[7:0];
								// s_axi.wstrb[3:0]
								writestate <= 2'b01;
								s_axi.wready <= 1'b1;
							end
						end
						4'h8: begin // status register
							// Cannot write here, skip
							writestate <= 2'b01;
							s_axi.wready <= 1'b1;
						end
						default/*2'hC*/: begin // control register
							// Cannot write here (yet), skip
							writestate <= 2'b01;
							s_axi.wready <= 1'b1;
						end
					endcase
				end
			end
			2'b01: begin
				if (s_axi.bready) begin
					s_axi.bvalid <= 1'b1;
					writestate <= 2'b10;
				end
			end
			default/*2'b10*/: begin
				s_axi.wready <= 1'b0;
				s_axi.bvalid <= 1'b0;
				writestate <= 2'b00;
			end
		endcase
	end
end

always @(posedge uartbaseclock) begin
	if (~aresetn) begin
		s_axi.rlast <= 1'b1;
		s_axi.arready <= 1'b0;
		s_axi.rvalid <= 1'b0;
		s_axi.rresp <= 2'b00;
	end else begin
		// read address
		uartrcvre <= 1'b0;
		case (raddrstate)
			2'b00: begin
				if (s_axi.arvalid) begin
					s_axi.arready <= 1'b1;
					raddrstate <= 2'b01;
				end
			end
			2'b01: begin
				s_axi.arready <= 1'b0;
				case (s_axi.araddr[3:0])
					4'h0: begin // rx data
						uartrcvre <= 1'b1;
						raddrstate <= 2'b10;
					end
					4'h4: begin // tx data
						// cannot read this, skip
						s_axi.rdata[31:0] <= 32'd0;
						s_axi.rvalid <= 1'b1;
						raddrstate <= 2'b11;
					end
					4'h8: begin // status register
						s_axi.rdata[31:0] <= {29'd0, uarttxbusy, uartrcvfull, ~uartrcvempty};
						s_axi.rvalid <= 1'b1;
						raddrstate <= 2'b11;
					end
					default/*4'hC*/: begin // control register
						// cannot read this (yet), skip
						s_axi.rdata[31:0] <= 32'd0;
						s_axi.rvalid <= 1'b1;
						raddrstate <= 2'b11;
					end
				endcase
			end
			2'b10: begin
				// master ready to accept
				if (s_axi.rready & uartrcvvalid) begin
					s_axi.rdata[31:0] <= {uartrcvdout, uartrcvdout, uartrcvdout, uartrcvdout};
					s_axi.rvalid <= 1'b1;
					raddrstate <= 2'b11; // delay one clock for master to pull down arvalid
				end
			end
			default/*2'b11*/: begin
				// at this point master should have responded properly with arvalid=0
				s_axi.rvalid <= 1'b0;
				raddrstate <= 2'b00;
			end
		endcase
	end
end

endmodule
