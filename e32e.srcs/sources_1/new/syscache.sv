`timescale 1ns / 1ps

`include "shared.vh"

module systemcache(
	input wire aclk,
	input wire aresetn,
	// custom bus to cpu
	input wire uncached,
	input wire [7:0] line,
	input wire [16:0] tag,
	input wire [3:0] offset,
	input wire [2:0] dcacheop,
	input wire [31:0] addr,
	input wire [31:0] din,
	output logic [31:0] dout,
	input wire [3:0] wstrb,
	input wire ren,
	input wire ifetch,
	output logic rready,
	output logic wready,
	axi_if.master a4buscached,
	axi_if.master a4busuncached );

logic [31:0] cacheaddress;
data_t cachedin[0:3];
data_t cachedout[0:3]; // x4 128 bits
logic memwritestrobe = 1'b0;
logic memreadstrobe = 1'b0;

logic [31:0] ucaddrs;
logic [31:0] ucdout;
wire [31:0] ucdin;
logic [3:0] ucwstrb = 4'h0;
logic ucre = 1'b0;
wire ucwritedone;
wire ucreaddone;

logic [3:0] bsel = 4'h0;			// copy of wstrobe
logic [1:0] rwmode = 2'b00;			// r/w mode bits
logic [16:0] ptag;					// previous cache tag (17 bits)
logic [16:0] ctag;					// current cache tag (17 bits)
logic [3:0] coffset;				// current word offset 0..15
logic [8:0] cline;					// current cache line 0..511

logic cachelinenowb[0:511];			// cache line does not need write back
logic [16:0] cachelinetags[0:511];	// cache line tags (17 bits)

logic [63:0] cachewe = 64'd0;		// byte select for 64 byte cache line
logic [511:0] cdin;					// input data to write to cache
wire [511:0] cdout;					// output data read from cache

logic flushing = 1'b0;				// high during cache flush operation
logic cacheid = 1'b0;				// 0: D$, 1: I$
logic [7:0] dccount = 8'h00;		// line counter for cache flush/invalidate ops

logic [8:0] cacheaccess;
always_comb begin
	if (flushing)
		cacheaccess = {cacheid, dccount};
	else
		cacheaccess = {ifetch, line};
end

wire rsta_busy;
cachemem CacheMemory512(
	.addra(cacheaccess),		// current cache line
	.clka(aclk),				// cache clock
	.dina(cdin),				// updated cache data to write
	.wea(cachewe),				// write strobe for current cache line
	.douta(cdout),				// output of currently selected cache line
	.rsta(~aresetn),			// Reset
	.rsta_busy(rsta_busy) );	// Reset busy

initial begin
	integer i;
	for (int i=0; i<512; i=i+1) begin	// 512 lines total (0..255 D$, 256..511 I$)
		cachelinenowb[i] = 1'b1;		// cache lines do not require write-back for initial cache-miss
		cachelinetags[i] = 17'h1ffff;	// point at the very end of cacheable space
	end
end

// ----------------------------------------------------------------------------
// cached/uncached memory controllers
// ----------------------------------------------------------------------------

wire rdone, wdone;
cachedmemorycontroller CMEMCTL(
	.aclk(aclk),
	.areset_n(aresetn),
	// From cache
	.addr(cacheaddress),
	.din(cachedout),
	.dout(cachedin),
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

typedef enum logic [4:0] {
	IDLE,
	CWRITE, CREAD,
	UCWRITE, UCWRITEDELAY, UCREAD, UCREADDELAY,
	CWBACK, CWBACKWAIT,
	CPOPULATE, CPOPULATEWAIT, CUPDATE, CUPDATEDELAY,
	CDATANOFLUSHBEGIN, CDATANOFLUSHSTEP,
	CDATAFLUSHBEGIN, CDATAFLUSHWAITCREAD, CDATAFLUSH, CDATAFLUSHSKIP, CDATAFLUSHWAIT } cachestatetype;
cachestatetype cachestate = IDLE;

wire cachehit = ctag == ptag ? 1'b1 : 1'b0;

always_ff @(posedge aclk) begin
	if (~aresetn) begin
		cachestate <= IDLE;
		memwritestrobe <= 1'b0;
		memreadstrobe <= 1'b0;
	end else begin

		memwritestrobe <= 1'b0;
		memreadstrobe <= 1'b0;
		wready <= 1'b0;
		rready <= 1'b0;
		ucwstrb <= 4'h0;
		ucre <= 1'b0;
		cachewe <= 64'd0;

		case (cachestate)
			IDLE : begin
				rwmode <= {ren, |wstrb};					// Record r/w mode
				bsel <= wstrb;								// Write byte select
				coffset <= offset;							// Cache offset 0..15
				cline <= {ifetch, line};					// Cache line
				ctag <= tag;								// Cache tag 00000..1ffff
				ptag <= cachelinetags[{ifetch, line}];		// Previous cache tag

				if (dcacheop[0]) begin
					// Start cache flush / invalidate op
					dccount <= 8'h00;
					cacheid <= dcacheop[2];
					cachestate <= dcacheop[1] ? CDATAFLUSHBEGIN : CDATANOFLUSHBEGIN;
				end else begin
					case ({ren, |wstrb})
						3'b001: cachestate <= uncached ? UCWRITE : CWRITE;
						3'b010: cachestate <= uncached ? UCREAD : CREAD;
						default: cachestate <= IDLE;
					endcase
				end
			end

			CDATANOFLUSHBEGIN: begin
				// Nothing to write from cache for next time around
				cachelinenowb[{cacheid, dccount}] <= 1'b1;
				// Change tag to cause a cache miss for next time around
				cachelinetags[{cacheid, dccount}] <= 17'h1ffff;
				cachestate <= CDATANOFLUSHSTEP;
			end

			CDATANOFLUSHSTEP: begin
				// Go to next line
				dccount <= dccount + 8'd1;
				// Finish our mock 'write' operation
				wready <= dccount == 8'hFF;
				// Repeat until we process line 0xFF and go back to idle state
				cachestate <= dccount == 8'hFF ? IDLE : CDATANOFLUSHBEGIN;
			end
			
			CDATAFLUSHBEGIN: begin
				// Switch cache address to use flush counter
				flushing <= 1'b1;
				cachestate <= CDATAFLUSHWAITCREAD;
			end

			CDATAFLUSHWAITCREAD: begin
				// One clock delay to read cache value at {cacheid, dccount}
				cachestate <= CDATAFLUSH;
			end

			CDATAFLUSH: begin
				// Nothing to write from cache for next time around
				cachelinenowb[{cacheid, dccount}] <= 1'b1;

				// We keep the tag same, since we only want to make sure data is written back, not evicted

				// Either write back to memory or skip
				if (cachelinenowb[{cacheid, dccount}]) begin
					// Skip this line if it doesn't need a write back operation
					cachestate <= CDATAFLUSHSKIP;
				end else begin // Otherwise, skip write back
					// Write current line back to RAM
					cacheaddress <= {1'b0, cachelinetags[{cacheid, dccount}], dccount, 6'd0};
					cachedout <= {cdout[127:0], cdout[255:128], cdout[383:256], cdout[511:384]};
					memwritestrobe <= 1'b1;
					// We're done if this Was the last write
					cachestate <= CDATAFLUSHWAIT;
				end
			end

			CDATAFLUSHSKIP: begin
				// Go to next line
				dccount <= dccount + 8'd1;
				// Stop 'flushing' mode if we're done
				flushing <= dccount != 8'hFF;
				// Finish our mock 'write' operation if we're done
				wready <= dccount == 8'hFF;
				// Repeat until we process line 0xFF and go back to idle state
				cachestate <= dccount == 8'hFF ? IDLE : CDATAFLUSHWAITCREAD;
			end

			CDATAFLUSHWAIT: begin
				if (wdone) begin
					// Go to next line
					dccount <= dccount + 8'd1;
					// Stop 'flushing' mode if we're done
					flushing <= dccount != 8'hFF;
					// Finish our mock 'write' operation if we're done
					wready <= dccount == 8'hFF;
					// Repeat until we process line 0xFF and go back to idle state
					cachestate <= dccount == 8'hFF ? IDLE : CDATAFLUSHWAITCREAD;
				end else begin
					// Memory write didn't complete yet
					cachestate <= CDATAFLUSHWAIT;
				end
			end

			UCWRITE: begin
				ucaddrs <= addr;
				ucdout <= din;
				ucwstrb <= bsel;
				cachestate <= UCWRITEDELAY;
			end

			UCWRITEDELAY: begin
				if (ucwritedone) begin
					wready <= 1'b1;
					cachestate <= IDLE;
				end else begin
					cachestate <= UCWRITEDELAY;
				end
			end

			UCREAD: begin
				ucaddrs <= addr;
				ucre <= 1'b1;
				cachestate <= UCREADDELAY;
			end

			UCREADDELAY: begin
				if (ucreaddone) begin
					dout <= ucdin;
					rready <= 1'b1;
					cachestate <= IDLE;
				end else begin
					cachestate <= UCREADDELAY;
				end
			end

			CWRITE: begin
				if (cachehit) begin
					cdin <= {din, din, din, din, din, din, din, din, din, din, din, din, din, din, din, din};	// Incoming data replicated to be masked by cachewe
					case (coffset)
						4'b0000:  cachewe <= { 60'd0, bsel        };
						4'b0001:  cachewe <= { 56'd0, bsel, 4'd0  };
						4'b0010:  cachewe <= { 52'd0, bsel, 8'd0  };
						4'b0011:  cachewe <= { 48'd0, bsel, 12'd0 };
						4'b0100:  cachewe <= { 44'd0, bsel, 16'd0 };
						4'b0101:  cachewe <= { 40'd0, bsel, 20'd0 };
						4'b0110:  cachewe <= { 36'd0, bsel, 24'd0 };
						4'b0111:  cachewe <= { 32'd0, bsel, 28'd0 };
						4'b1000:  cachewe <= { 28'd0, bsel, 32'd0 };
						4'b1001:  cachewe <= { 24'd0, bsel, 36'd0 };
						4'b1010:  cachewe <= { 20'd0, bsel, 40'd0 };
						4'b1011:  cachewe <= { 16'd0, bsel, 44'd0 };
						4'b1100:  cachewe <= { 12'd0, bsel, 48'd0 };
						4'b1101:  cachewe <= { 8'd0,  bsel, 52'd0 };
						4'b1110:  cachewe <= { 4'd0,  bsel, 56'd0 };
						default:  cachewe <= {        bsel, 60'd0 }; // 4'b1111
					endcase
					// This cacbe line needs to be written back to memory on next miss
					cachelinenowb[cline] <= 1'b0;
					wready <= 1'b1;
					cachestate <= IDLE;
				end else begin
					cachestate <= cachelinenowb[cline] ? CPOPULATE : CWBACK;
				end
			end

			CREAD: begin
				if (cachehit) begin
					// Return word directly from cache
					case (coffset)
						4'b0000:  dout <= cdout[31:0];
						4'b0001:  dout <= cdout[63:32];
						4'b0010:  dout <= cdout[95:64];
						4'b0011:  dout <= cdout[127:96];
						4'b0100:  dout <= cdout[159:128];
						4'b0101:  dout <= cdout[191:160];
						4'b0110:  dout <= cdout[223:192];
						4'b0111:  dout <= cdout[255:224];
						4'b1000:  dout <= cdout[287:256];
						4'b1001:  dout <= cdout[319:288];
						4'b1010:  dout <= cdout[351:320];
						4'b1011:  dout <= cdout[383:352];
						4'b1100:  dout <= cdout[415:384];
						4'b1101:  dout <= cdout[447:416];
						4'b1110:  dout <= cdout[479:448];
						default:  dout <= cdout[511:480]; // 4'b1111
					endcase
					rready <= 1'b1;
					cachestate <= IDLE;
				end else begin // Cache miss when ctag != ptag
					cachestate <= cachelinenowb[cline] ? CPOPULATE : CWBACK;
				end
			end

			CWBACK : begin
				// Use old memory address with device selector, aligned to cache boundary, top bit ignored (cached address)
				cacheaddress <= {1'b0, ptag, cline[7:0], 6'd0};
				cachedout <= {cdout[127:0], cdout[255:128], cdout[383:256], cdout[511:384]};
				memwritestrobe <= 1'b1;
				cachestate <= CWBACKWAIT;
			end

			CWBACKWAIT: begin
				cachestate <= wdone ? CPOPULATE : CWBACKWAIT;
			end

			CPOPULATE : begin
				// Same as current memory address with device selector, aligned to cache boundary, top bit ignored (cached address)
				cacheaddress <= {1'b0, ctag, cline[7:0], 6'd0};
				memreadstrobe <= 1'b1;
				cachestate <= CPOPULATEWAIT;
			end

			CPOPULATEWAIT: begin
				cachestate <= rdone ? CUPDATE : CPOPULATEWAIT;
			end

			CUPDATE: begin
				cachewe <= 64'hFFFFFFFFFFFFFFFF; // All entries
				cdin <= {cachedin[3], cachedin[2], cachedin[1], cachedin[0]}; // Data from memory
				cachestate <= CUPDATEDELAY;
			end

			default: begin // CUPDATEDELAY
				ptag <= ctag;
				cachelinetags[cline] <= ctag;
				// No need to write back since contents are valid and unmodifed
				cachelinenowb[cline] <= 1'b1;
				cachestate <= (rwmode == 2'b01) ? CWRITE : CREAD;
			end
		endcase
	end
end

endmodule
