`timescale 1ns / 1ps

import axi_pkg::*;

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

	typedef enum logic [2:0] {IDLE, RADDR, RDATA, WADDR, WDATA, WRESP} state_type;
	state_type state = IDLE;

	logic [1:0] len_cnt;
	logic [1:0] rdata_cnt;
	assign m_axi.arlen = burstlen - 1;
	assign m_axi.arsize = SIZE_16_BYTE; // 128bit read bus
	assign m_axi.arburst = BURST_INCR;
	assign m_axi.awlen = burstlen - 1;
	assign m_axi.awsize = SIZE_16_BYTE; // 128bit write bus
	assign m_axi.awburst = BURST_INCR;

	always_ff @(posedge aclk) begin
		if (~areset_n) begin
			rdata_cnt <= 0;
		end else begin
			if (state == RDATA && m_axi.rvalid /* && m_axi.rready*/) begin
				dout[rdata_cnt] <= m_axi.rdata;
				rdata_cnt <= rdata_cnt + 1;
			end else begin
				rdata_cnt <= 2'd0;
			end
		end
	end

	always_ff @(posedge aclk) begin
		if (~areset_n) begin
			m_axi.arvalid <= 0;
			m_axi.awvalid <= 0;
			m_axi.rready <= 0;
			m_axi.wvalid <= 0;
			m_axi.wstrb <= 16'h0000;
			m_axi.wlast <= 0;
			m_axi.bready <= 0;
			len_cnt <= 0;
			state <= IDLE;
		end else begin
			rdone <= 1'b0;
			wdone <= 1'b0;

			case (state)
				IDLE : begin
					if (start_read) begin
						m_axi.araddr  <= addr; // NOTE: MUST be 32 byte aligned! [31:5]
						m_axi.arvalid <= 1;
					end
					if (start_write) begin
						m_axi.awaddr <= addr; // NOTE: MUST be 32 byte aligned! [31:5]
						m_axi.awvalid <= 1;
					end
					state <= (start_read) ? RADDR : ((start_write) ? WADDR : IDLE);
				end

				RADDR : begin
					if (/*m_axi.arvalid && */m_axi.arready) begin
						m_axi.arvalid <= 0;
						m_axi.rready <= 1;
						state <= RDATA;
					end else begin
						state <= RADDR;
					end
				end

				RDATA : begin
					if (m_axi.rvalid  /*&& m_axi.rready*/ && m_axi.rlast) begin
						m_axi.rready <= 0;
						rdone <= 1'b1;
						state <= IDLE;
					end else begin
						state <= RDATA;
					end
				end

				WADDR : begin
					if (/*m_axi.awvalid &&*/ m_axi.awready) begin
						m_axi.awvalid <= 0;
						state <= WDATA;
					end else begin
						state <= WADDR;
					end
				end

				WDATA : begin
					m_axi.wdata <= din[len_cnt];
					m_axi.wstrb <= 16'hFFFF;
					m_axi.wvalid <= 1;
					m_axi.wlast <= (len_cnt == (burstlen-1)) ? 1 : 0;
					if (/*m_axi.wvalid &&*/ m_axi.wready)
						len_cnt <= len_cnt + 1;
					if (/*m_axi.wvalid &&*/ m_axi.wready && (len_cnt == (burstlen-1))/*m_axi.wlast*/) begin
						m_axi.bready <= 1;
						state <= WRESP;
					end else begin
						state <= WDATA;
					end
				end

				default/*WRESP*/ : begin
					m_axi.wvalid <= 0;
					m_axi.wstrb <= 16'h0000;
					m_axi.wlast <= 0;
					if (m_axi.bvalid /*&& m_axi.bready*/) begin
						m_axi.bready <= 0;
						wdone <= 1'b1;
						state <= IDLE;
					end else begin
						state <= WRESP;
					end
				end
			endcase
		end
	end
endmodule
