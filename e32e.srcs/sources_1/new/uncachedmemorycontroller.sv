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

	typedef enum logic [2 : 0] {IDLE, RADDR, RDATA, WADDR, WDATA, WRESP} state_type;
	state_type state = IDLE;

	assign m_axi.arlen = 0;
	assign m_axi.arsize = SIZE_4_BYTE;
	assign m_axi.arburst = BURST_FIXED;

	assign m_axi.awlen = 0;
	assign m_axi.awsize = SIZE_4_BYTE;
	assign m_axi.awburst = BURST_FIXED;

	always_ff @(posedge aclk) begin
		if (~areset_n) begin
			//
		end else begin
			if (state == RDATA && m_axi.rvalid /* && m_axi.rready*/) dout <= m_axi.rdata[31:0];
		end
	end

	logic [3:0] wbsel = 4'h0;

	always_ff @(posedge aclk) begin
		if (~areset_n) begin
			m_axi.arvalid <= 0;
			m_axi.awvalid <= 0;
			m_axi.rready <= 0;
			m_axi.wvalid <= 0;
			m_axi.wstrb <= 16'h0000;
			m_axi.wlast <= 0;
			m_axi.bready <= 0;
			state <= IDLE;
		end else begin
			rdone <= 1'b0;
			wdone <= 1'b0;

			case (state)
				IDLE : begin
					if (re) begin
						m_axi.araddr  <= addr;
						m_axi.arvalid <= 1;
					end
					if (|wstrb) begin
						wbsel <= wstrb;
						m_axi.awaddr <= addr;
						m_axi.awvalid <= 1;
					end
					state <= (re) ? RADDR : ((|wstrb) ? WADDR : IDLE);
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
						m_axi.wdata <= {96'd0, din};
						m_axi.wstrb <= {12'd0, wbsel};
						m_axi.wvalid <= 1;
						m_axi.wlast <= 1;
						state <= WDATA;
					end else begin
						state <= WADDR;
					end
				end

				WDATA : begin
					if (/*m_axi.wvalid &&*/ m_axi.wready) begin
						m_axi.bready <= 1;
						m_axi.wvalid <= 0;
						m_axi.wstrb <= 16'h0000;
						m_axi.wlast <= 0;
						state <= WRESP;
					end else begin
						state <= WDATA;
					end
				end

				default/*WRESP*/ : begin
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
