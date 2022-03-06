`timescale 1ns / 1ps

`include "shared.vh"

module systemcache(
	input wire aclk,
	input wire aresetn,
	// custom bus to cpu
	input wire uncached,
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
data_t cachedin[0:1];
data_t cachedout[0:1];
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
logic [1:0] rwmode = 2'b00;			// R/W mode bits
logic [16:0] ptag;					// previous cache tag (17 bits)
logic [16:0] ctag;					// current cache tag (17 bits)
logic [3:0] coffset;				// current word offset 0..15
logic [8:0] cline;					// current cache line 0..511

logic cachelinevalid[0:511];		// cache line valid bits
logic [16:0] cachelinetags[0:511];	// cache line tags (17 bits)

logic [63:0] cachewe = 64'd0;		// byte select for 64 byte cache line
logic [511:0] cdin;					// input data to write to cache
wire [511:0] cdout;					// output data read from cache

cachemem CacheMemory512(
	.addra({ifetch,addr[13:6]}/*cline*/),	// current cache line
	.clka(aclk),					// cache clock
	.dina(cdin),					// updated cache data to write
	.wea(cachewe),					// write strobe for current cache line
	.douta(cdout) );				// output of currently selected cache line

initial begin
	integer i;
	// all pages are 'clean', all tags are invalid and cache is zeroed out by default
	for (int i=0; i<512; i=i+1) begin	// 512 lines (256 I$, 256 D$)
		cachelinevalid[i] = 1'b1;		// cache lines are all valid by default, so no write-back for initial cache-miss
		cachelinetags[i]  = 17'h1ffff;	// all bits set for default tag
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

typedef enum logic [3:0] {IDLE, CWRITE, CREAD, UCWRITE, UCWRITEDELAY, UCREAD, UCREADDELAY, CWBACK, CWBACKWAIT, CPOPULATE, CPOPULATEWAIT, CUPDATE, CUPDATEDELAY} cachestatetype;
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
				coffset <= addr[5:2];						// Cache offset 0..15
				cline <= {ifetch,addr[13:6]};				// Cache line
				ctag <= addr[30:14];						// Cache tag 00000..1ffff
				ptag <= cachelinetags[{ifetch,addr[13:6]}];	// Previous cache tag

				case ({ren, |wstrb})
					2'b01: cachestate <= uncached ? UCWRITE : CWRITE;
					2'b10: cachestate <= uncached ? UCREAD : CREAD;
					default: cachestate <= IDLE;
				endcase
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
					// This cacbe line needs eviction next time we miss
					cachelinevalid[cline] <= 1'b0;
					wready <= 1'b1;
					cachestate <= IDLE;
				end else begin
					cachestate <= ~cachelinevalid[cline] ? CWBACK : CPOPULATE;
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
					cachestate <= ~cachelinevalid[cline] ? CWBACK : CPOPULATE;
				end
			end

			CWBACK : begin
				// Use old memory address with device selector, aligned to cache boundary, top bit ignored (cached address)
				cacheaddress <= {1'b0, ptag, cline[7:0], 6'd0};
				cachedout <= {cdout[255:0], cdout[511:256]};
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
				cdin <= {cachedin[1], cachedin[0]}; // Data from memory
				cachestate <= CUPDATEDELAY;
			end

			default: begin // CUPDATEDELAY
				ptag <= ctag;
				cachelinetags[cline] <= ctag;
				cachelinevalid[cline] <= 1'b1;
				cachestate <= (rwmode == 2'b01) ? CWRITE : CREAD;
			end
		endcase
	end
end

endmodule
