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

assign m_axi.arsize = SIZE_16_BYTE; // 128bit read bus
assign m_axi.arburst = BURST_INCR;

assign m_axi.awlen = 0;				// one burst
assign m_axi.awsize = SIZE_16_BYTE; // 128bit write bus
assign m_axi.awburst = BURST_INCR;

assign m_axi.awvalid = 0;
assign m_axi.awaddr = 'd0;
assign m_axi.wvalid = 0;
assign m_axi.wstrb = 16'h0000; // For raster unit or DMA, this will be the byte write mask for a 16 pixel horizontal tile
assign m_axi.wlast = 0;
assign m_axi.wdata = 'd0;
assign m_axi.bready = 0;

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
wire dmaqueuevalid;
wire dmaqueueempty;
logic dmaqueuewe = 1'b0;
logic [127:0] dmaqueuedin = 0;
logic dmaqueuere = 1'b0;
wire [127:0] dmaqueuedout;

dmaqueue dmaqueueinst(
	.full(),
	.din(dmaqueuedin),
	.wr_en(dmaqueuewe),
	.empty(dmaqueueempty),
	.dout(dmaqueuedout),
	.rd_en(dmaqueuere),
	.valid(dmaqueuvalid),
	.clk(aclk),
	.srst(~aresetn) );

logic [31:0] dmasourceaddr;
logic [31:0] dmatargetaddr;
logic [31:0] dmabytecount;

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
					dmabytecount <= dmafifodout;
					// Advance FIFO
					cmdre <= 1'b1;
					cmdmode <= FINALIZE;
				end
			end

			DMAENQUEUE: begin
				dmaqueuedin <= {dmasourceaddr, dmatargetaddr, dmabytecount, dmabytecount};
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

typedef enum logic [2:0] {DETECTCMD, STARTDMA} dmastatetype;
dmastatetype dmastate = DETECTCMD;
logic [127:0] dmaoperation;

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
					// TODO: Start the burst read/write ops
					// TBD: This unit doesn't handle misaligned copies yet
					dmaoperation <= dmaqueuedout;
					dmainprogress <= 1'b1;
					// Advance FIFO
					dmaqueuere <= 1'b1;
					dmastate <= STARTDMA;
				end
			end
			STARTDMA: begin
				// TODO: Generate leadmask / trailmask for misaligned copies (start address and/or length not a multiple of 128 bits)
				// ...

				// Mark end of DMA for the CPU when done
				dmainprogress <= 1'b0;

				// Dummy state, go back to where we were
				dmastate <= DETECTCMD;
			end
		endcase
	end
end

endmodule
