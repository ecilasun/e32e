`timescale 1ns / 1ps

module cachedmemorycontroller (
	// Clock/reset
	input wire aclk,
	input wire areset_n,
	// Custom bus from cache controller
	input wire [31:0] addr,
	output data_t dout[0:3],
	input data_t din[0:3], // x4 128 bits
	input wire start_read,
	input wire start_write,
	output logic wdone,
	output logic rdone,
	// Memory device bus
	axi_if.master m_axi );

	localparam burstlen = 4; // x4 128 bit reads or writes

	// Write
	logic [1:0] wdata_cnt;
	assign m_axi.awlen = burstlen - 1;
	assign m_axi.awsize = SIZE_16_BYTE; // 128bit write bus
	assign m_axi.awburst = BURST_INCR;

	typedef enum logic [1:0] {WIDLE, WADDR, WDATA, WRESP} writestate_type;
	writestate_type writestate = WIDLE;

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
					wdata_cnt <= 0;
					m_axi.awaddr <= addr; // NOTE: MUST be 64 byte aligned! {[31:7], 6'd0}
					m_axi.awvalid <= start_write;
					writestate <= start_write ? WADDR : WIDLE;
				end

				WADDR : begin
					if (/*m_axi.awvalid &&*/ m_axi.awready) begin
						m_axi.awvalid <= 0;
						m_axi.wdata <= din[wdata_cnt];
						m_axi.wstrb <= 16'hFFFF;
						m_axi.wvalid <= 1;
						m_axi.wlast <= (wdata_cnt == (burstlen-1)) ? 1 : 0;
						wdata_cnt <= wdata_cnt + 1;
						writestate <= WDATA;
					end else begin
						writestate <= WADDR;
					end
				end

				WDATA : begin
					if (/*m_axi.wvalid &&*/ m_axi.wready) begin
						m_axi.wdata <= din[wdata_cnt];
						m_axi.wlast <= (wdata_cnt == (burstlen-1)) ? 1 : 0;
						m_axi.bready <= (wdata_cnt == (burstlen-1)) ? 1 : 0;
						wdata_cnt <= wdata_cnt + 1;
					end
					writestate <= (wdata_cnt == (burstlen-1)) ? WRESP : WDATA;
				end

				default/*WRESP*/ : begin
					m_axi.wvalid <= 0;
					m_axi.wstrb <= 16'h0000;
					m_axi.wlast <= 0;
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

	// Read
	logic [1:0] rdata_cnt;
	assign m_axi.arlen = burstlen - 1;
	assign m_axi.arsize = SIZE_16_BYTE; // 128bit read bus
	assign m_axi.arburst = BURST_INCR;

	typedef enum logic [2:0] {RIDLE, RADDR, RDATA} readstate_type;
	readstate_type readstate = RIDLE;

	always_ff @(posedge aclk) begin
		if (~areset_n) begin
			m_axi.arvalid <= 0;
			m_axi.rready <= 0;
			readstate <= RIDLE;
		end else begin

			rdone <= 1'b0;

			case (readstate)
				RIDLE : begin
					rdata_cnt <= 0;
					m_axi.araddr <= addr; // NOTE: MUST be 64 byte aligned! {[31:7], 6'd0}
					m_axi.arvalid <= start_read;
					readstate <= start_read ? RADDR : RIDLE;
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
					if (m_axi.rvalid  /*&& m_axi.rready*/) begin
						dout[rdata_cnt] <= m_axi.rdata;
						rdata_cnt <= rdata_cnt + 1;
						m_axi.rready <= ~m_axi.rlast;
						rdone <= m_axi.rlast;
						readstate <= m_axi.rlast ? RIDLE : RDATA;
					end else begin
						readstate <= RDATA;
					end
				end
			endcase
		end
	end
endmodule
