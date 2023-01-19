`timescale 1ns / 1ps

module dmacore(
	input wire aclk,
	input wire clk25,
	input wire clk250,
	input wire aresetn,
	axi_if.master m_axi,
	input wire dmafifoempty,
	input wire [31:0] dmafifodout,
	output wire dmafifore,
	input wire dmafifovalid,
	output wire dmabusy);

logic cmdre = 1'b0;
logic dmainprogress = 1'b0;
assign dmafifore = cmdre;
assign dmabusy = dmainprogress;

// ------------------------------------------------------------------------------------
// Setup
// ------------------------------------------------------------------------------------

logic [7:0] burstlen = 'd20;
logic dmastrobe = 1'b0;

assign m_axi.arlen = 0;	// one burst
assign m_axi.arsize = SIZE_16_BYTE; // 128bit read bus
assign m_axi.arburst = BURST_INCR;

assign m_axi.awlen = 0;				// one burst
assign m_axi.awsize = SIZE_16_BYTE; // 128bit write bus
assign m_axi.awburst = BURST_INCR;

// NOTE: First, set up the scanout address, then enable video scanout
logic [31:0] scanaddr = 32'h00000000;
logic [31:0] scanoffset = 0;
logic scanenable = 1'b0;

logic [5:0] rdata_cnt = 'd0;

// ------------------------------------------------------------------------------------
// Command FIFO
// ------------------------------------------------------------------------------------

typedef enum logic [2:0] {
	WCMD, DISPATCH,
	DMASOURCE,
	DMATARGET,
	DMALENGTH,
	DMAENQUEUE,
	FINALIZE } dmacmdmodetype;
dmacmdmodetype cmdmode = WCMD;

logic [31:0] dmacmd = 'd0;

// TODO: DMA queue FIFO and wires, first word fallthrough
wire dmaqueuefull;
wire dmaqueuevalid;
wire dmaqueueempty;
logic dmaqueuewe = 1'b0;
logic [95:0] dmaqueuedin = 0;
logic dmaqueuere = 1'b0;
wire [95:0] dmaqueuedout;

dmaqueue dmaqueueinst(
	.full(dmaqueuefull),
	.din(dmaqueuedin),
	.wr_en(dmaqueuewe),
	.empty(dmaqueueempty),
	.dout(dmaqueuedout),
	.rd_en(dmaqueuere),
	.valid(dmaqueuevalid),
	.clk(aclk),
	.srst(~aresetn) );

logic [31:0] dmasourceaddr;
logic [31:0] dmatargetaddr;
logic [31:0] dmablockcount;

always_ff @(posedge aclk) begin
	if (~aresetn) begin
		cmdmode <= WCMD;
	end else begin

		cmdre <= 1'b0;
		dmaqueuewe <= 1'b0;

		case (cmdmode)
			WCMD: begin
				if (dmafifovalid && ~dmafifoempty) begin
					dmacmd <= dmafifodout;
					// Advance FIFO
					cmdre <= 1'b1;
					// Dispatch cmd
					cmdmode <= DISPATCH;
				end
			end

			DISPATCH: begin
				case (dmacmd)
					32'h00000000:	cmdmode <= DMASOURCE;	// Source address, byte aligned
					32'h00000001:	cmdmode <= DMATARGET;	// Target address, byte aligned
					32'h00000002:	cmdmode <= DMALENGTH;	// Set length in bytes (divided into 128 bit blocks, r/w masks handle leading and trailing ledges)
					32'h00000003:	cmdmode <= DMAENQUEUE;	// Push current setup into DMA transfer queue
					default:		cmdmode <= FINALIZE;	// Invalid command, wait one clock and try next
				endcase
			end

			DMASOURCE: begin
				if (dmafifovalid && ~dmafifoempty) begin
					dmasourceaddr <= dmafifodout;
					// Advance FIFO
					cmdre <= 1'b1;
					cmdmode <= FINALIZE;
				end
			end

			DMATARGET: begin
				if (dmafifovalid && ~dmafifoempty) begin
					dmatargetaddr <= dmafifodout;
					// Advance FIFO
					cmdre <= 1'b1;
					cmdmode <= FINALIZE;
				end
			end

			DMALENGTH: begin
				if (dmafifovalid && ~dmafifoempty) begin
					// NOTE: Need to generate leadmask and trailmask for misaligned
					// start/end bits and manage the middle section count
					dmablockcount <= dmafifodout;
					// Advance FIFO
					cmdre <= 1'b1;
					cmdmode <= FINALIZE;
				end
			end

			DMAENQUEUE: begin
				dmaqueuedin <= {dmasourceaddr, dmatargetaddr, dmablockcount};
				dmaqueuewe <= 1'b1;
				// Advance FIFO
				cmdre <= 1'b1;
				cmdmode <= FINALIZE;
			end

			FINALIZE: begin
				cmdmode <= WCMD;
			end

		endcase
	end
end

// ------------------------------------------------------------------------------------
// DMA logic
// ------------------------------------------------------------------------------------

typedef enum logic [2:0] {DETECTCMD, STARTDMA, DMAREADSOURCE, COPYBLOCK, DMAWRITEDEST, DMACOMPLETERW, DMARESUME} dmastatetype;
dmastatetype dmastate = DETECTCMD;

logic [31:0] dmaop_source;
logic [31:0] dmaop_target;
logic [31:0] dmaop_count;
logic [127:0] copydata;

always_ff @(posedge aclk) begin
	if (~aresetn) begin
		m_axi.arvalid <= 0;
		m_axi.rready <= 0;
		dmastate <= DETECTCMD;
	end else begin

		dmaqueuere <= 1'b0;

		case (dmastate)
			DETECTCMD: begin
				// TODO: Instead of strobe, write command to a DMA fifo
				if (~dmaqueueempty && dmaqueuevalid) begin
					// TBD: This unit doesn't handle misaligned copies yet
					// TBD: This unit doesn't do burst copy yet

					dmaop_source <= dmaqueuedout[95:64];
					dmaop_target <= dmaqueuedout[63:32];
					dmaop_count <= dmaqueuedout[31:0];

					dmainprogress <= 1'b1;
					// Advance FIFO
					dmaqueuere <= 1'b1;
					dmastate <= STARTDMA;
				end
			end

			STARTDMA: begin
				// TODO: Generate leadmask / trailmask for misaligned copies (start address and/or length not a multiple of 128 bits)

				// Set up read
				m_axi.arvalid <= 1;
				m_axi.araddr <= dmaop_source;
				dmaop_source <= dmaop_source + 32'd16; // Next batch

				// Dummy state, go back to where we were
				dmastate <= DMAREADSOURCE;
			end

			DMAREADSOURCE: begin
				if (/*m_axi.arvalid && */m_axi.arready) begin
					m_axi.arvalid <= 0;
					m_axi.rready <= 1;
					dmastate <= COPYBLOCK;
				end
			end

			COPYBLOCK: begin
				if (m_axi.rvalid  /*&& m_axi.rready*/) begin
					m_axi.rready <= 1'b0;

					copydata <= m_axi.rdata;

					m_axi.awvalid = 1'b1;
					m_axi.awaddr = dmaop_target;
					dmaop_target <= dmaop_target + 32'd16; // Next batch

					dmastate <= DMAWRITEDEST;
				end
			end

			DMAWRITEDEST: begin
				if (/*m_axi.awvalid &&*/ m_axi.awready) begin
					m_axi.awvalid = 1'b0;

					m_axi.wvalid = 1'b1;
					m_axi.wstrb = 16'hFFFF; // TBD: depends on leadmask / trailmask
					m_axi.wdata <= copydata;
					m_axi.wlast = 1'b1;

					dmastate <= DMACOMPLETERW;
				end
			end

			DMACOMPLETERW: begin
				if (/*m_axi.wvalid &&*/ m_axi.wready) begin
					m_axi.wvalid <= 0;

					m_axi.wstrb <= 16'h0000;
					m_axi.wlast <= 0;
					m_axi.bready <= 1;

					dmaop_count <= dmaop_count - 'd1;
					dmastate <= DMARESUME;
				end
			end

			DMARESUME: begin
				if (m_axi.bvalid /*&& m_axi.bready*/) begin
					m_axi.bready <= 0;

					// Set up next read, if there's one
					m_axi.arvalid <= (dmaop_count == 'd0) ? 1'b0 : 1'b1;
					m_axi.araddr <= dmaop_source;
					dmaop_source <= dmaop_source + 32'd16; // Next batch

					// If we're done, listen to next command
					dmastate <= (dmaop_count == 'd0) ? DETECTCMD : DMAREADSOURCE;
					dmainprogress <= (dmaop_count == 'd0) ? 1'b0 : 1'b1;
				end
			end
	endcase
	end
end

endmodule
