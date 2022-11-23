`timescale 1ns / 1ps

module uncachedmemorycontroller (
	// Clock/reset
	input wire aclk,
	input wire areset_n,
	// Custom bus from cache controller
	input wire [31:0] addr,
	output logic [31:0] dout,
	input wire [31:0] din,
	input wire [3:0] wstrb,
	input wire re,
	output logic wdone,
	output logic rdone,
	// Memory mapped device bus
	axi_if.master m_axi );

	typedef enum logic [1 : 0] {RIDLE, RADDR, RDATA } read_state_type;
	typedef enum logic [1 : 0] {WIDLE, WADDR, WDATA, WRESP} write_state_type;
	read_state_type readstate = RIDLE;
	write_state_type writestate = WIDLE;

	assign m_axi.arlen = 0;
	assign m_axi.arsize = SIZE_4_BYTE;
	assign m_axi.arburst = BURST_FIXED;

	assign m_axi.awlen = 0;
	assign m_axi.awsize = SIZE_4_BYTE;
	assign m_axi.awburst = BURST_FIXED;

	logic [3:0] wbsel = 4'h0;
	logic [31:0] datain = 32'd0;

	always_ff @(posedge aclk) begin
		if (~areset_n) begin
			m_axi.arvalid <= 0;
			m_axi.rready <= 0;
			readstate <= RIDLE;
		end else begin

			rdone <= 1'b0;

			case (readstate)
				RIDLE : begin
					m_axi.araddr  <= addr;
					m_axi.arvalid <= re;
					readstate <= re ? RADDR : RIDLE;
				end

				RADDR : begin
					if (/*m_axi.arvalid && */m_axi.arready) begin
						m_axi.arvalid <= 0;
						m_axi.rready <= 1;
						readstate <= RDATA;
					end else begin
						readstate <= RADDR;
					end
				end

				RDATA : begin
					if (m_axi.rvalid  /*&& m_axi.rready*/ && m_axi.rlast) begin
						m_axi.rready <= 0;
						dout <= m_axi.rdata[31:0];
						rdone <= 1'b1;
						readstate <= RIDLE;
					end else begin
						readstate <= RDATA;
					end
				end
			endcase
		end
	end

	always_ff @(posedge aclk) begin
		if (~areset_n) begin
			m_axi.awvalid <= 0;
			m_axi.wvalid <= 0;
			m_axi.wstrb <= 16'h0000;
			m_axi.wlast <= 0;
			m_axi.bready <= 0;
			writestate <= WIDLE;
		end else begin

			wdone <= 1'b0;

			case (writestate)
				WIDLE : begin
					wbsel <= wstrb;
					datain <= din;
					m_axi.awaddr <= addr;
					m_axi.awvalid <= (|wstrb);
					writestate <= (|wstrb) ? WADDR : WIDLE;
				end

				WADDR : begin
					if (/*m_axi.awvalid &&*/ m_axi.awready) begin
						m_axi.awvalid <= 0;
						m_axi.wdata <= {96'd0, datain};
						m_axi.wstrb <= {12'd0, wbsel};
						m_axi.wvalid <= 1;
						m_axi.wlast <= 1;
						writestate <= WDATA;
					end else begin
						writestate <= WADDR;
					end
				end

				WDATA : begin
					if (/*m_axi.wvalid &&*/ m_axi.wready) begin
						m_axi.wvalid <= 0;
						m_axi.wstrb <= 16'h0000;
						m_axi.wlast <= 0;
						m_axi.bready <= 1;
						writestate <= WRESP;
					end else begin
						writestate <= WDATA;
					end
				end

				default/*WRESP*/ : begin
					if (m_axi.bvalid /*&& m_axi.bready*/) begin
						m_axi.bready <= 0;
						wdone <= 1'b1;
						writestate <= WIDLE;
					end else begin
						writestate <= WRESP;
					end
				end
			endcase
		end
	end

endmodule
