`timescale 1ns / 1ps

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
	input wire rdone,
	input wire wdone,
	// cached (memory) controller
	output logic [31:0] cacheaddress,
	output data_t cachedout[0:15],
	input data_t cachedin[0:15],
	output logic memwritestrobe,
	output logic memreadstrobe,
	// uncached (memory mapped device) controller
	output logic [31:0] ucaddrs,
	output logic [31:0] ucdout,
	output logic [3:0] ucwstrb,
	input ucwritedone,
	input wire [31:0] ucdin,
	output logic ucre,
	input wire ucreaddone );

logic [3:0] bsel = 4'h0;		// copy of wstrobe
logic [1:0] rwmode = 2'b00;		// R/W mode bits
logic [13:0] ptag;				// previous cache tag (14 bits)
logic [13:0] ctag;				// current cache tag (14 bits)
logic [3:0] coffset;			// current word offset 0..15 (each cache line is 16 words (256bits))
wire [8:0] cline = addr[14:6];	// current cache line 0..511

logic ddr3valid[0:511];			// cache line valid bits
logic [13:0] ddr3tags[0:511];	// cache line tags (14 bits)

logic [63:0] cachewe = 64'd0;	// byte select for 64 byte cache line
logic [511:0] cdin;				// input data to write to cache
wire [511:0] cdout;				// output data read from cache

cachemem CacheMemory512(
	.addra(cline), 				// current cache line
	.clka(aclk),				// cache clock
	.dina(cdin),				// updated cache data to write
	.wea(cachewe),				// write strobe for current cache line
	.douta(cdout) );			// output of currently selected cache line

initial begin
	integer i;
	// all pages are 'clean', all tags are invalid and cache is zeroed out by default
	for (int i=0; i<512; i=i+1) begin	// 512 lines, 8 words each
		ddr3valid[i] = 1'b1;			// cache lines are all valid by default, so no write-back for initial cache-miss
		ddr3tags[i]  = 14'h3fff;		// all bits set for default tag
	end
end

typedef enum logic [3:0] {IDLE, CWRITE, CREAD, CREADDELAY, UCWRITE, UCWRITEDELAY, UCREAD, UCREADDELAY, CWBACK, CWBACKWAIT, CPOPULATE, CPOPULATEWAIT, CUPDATE, CUPDATEDELAY} cachestatetype;
cachestatetype cachestate = IDLE;

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
				rwmode <= {ren, |wstrb};	// Record r/w mode
				bsel <= wstrb;				// Write byte select
				coffset <= addr[5:2];		// Cache offset 0..15
				//cline <= addr[14:6];		// Cache line 0..511
				ctag <= addr[28:15];		// Cache tag 0000..3fff
				ptag <= ddr3tags[cline];	// Previous cache tag

				// Cache hit when ctag == ptag, also uncached will force a cache hit
				if ((addr[28:15] == ddr3tags[cline]) || uncached) begin
					case ({ren, |wstrb})
						2'b01: cachestate <= uncached ? UCWRITE : CWRITE;
						2'b10: cachestate <= uncached ? UCREAD : CREAD;
						default: cachestate <= IDLE;
					endcase
				end else begin // Cache miss when ctag != ptag
					case ({ren, |wstrb})
						2'b01, 2'b10: cachestate <= ~ddr3valid[cline] ? CWBACK : CPOPULATE;
						default: cachestate <= IDLE;
					endcase
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
				ddr3valid[cline] <= 1'b0;
				wready <= 1'b1;
				cachestate <= IDLE;
			end
			
			/*CREAD: begin
				// 1 clock latency for read
				$display("Cache read waitstate.");
				cachestate <= CREADDELAY;
			end*/

			CREAD/*DELAY*/: begin
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
			end

			CWBACK : begin
				// Use old tag since this is from a different address (device selector stripped since we're connected to one known device, we also drop ifetch as it's not part of the address)
				cacheaddress <= {3'd0, ptag, cline, 6'd0}; // 16 word aligned
				cachedout <= {
					cdout[31:0], cdout[63:32], cdout[95:64], cdout[127:96], cdout[159:128], cdout[191:160], cdout[223:192], cdout[255:224],
					cdout[287:256], cdout[319:288], cdout[351:320], cdout[383:352], cdout[415:384], cdout[447:416], cdout[479:448], cdout[511:480] };
				memwritestrobe <= 1'b1;
				cachestate <= CWBACKWAIT;
			end

			CWBACKWAIT: begin
				cachestate <= wdone ? CPOPULATE : CWBACKWAIT;
			end

			CPOPULATE : begin
				// Same as current memory address, minus the device selector (since we're connected to one known device), aligned to cache boundary
				cacheaddress <= {3'd0, ctag, cline, 6'd0}; // 16 word aligned
				memreadstrobe <= 1'b1;
				cachestate <= CPOPULATEWAIT;
			end

			CPOPULATEWAIT: begin
				cachestate <= rdone ? CUPDATE : CPOPULATEWAIT;
			end

			CUPDATE: begin
				cachewe <= 64'hFFFFFFFFFFFFFFFF; // All entries
				cdin <= {
					cachedin[15], cachedin[14], cachedin[13], cachedin[12], cachedin[11], cachedin[10], cachedin[9], cachedin[8],
					cachedin[7], cachedin[6], cachedin[5], cachedin[4], cachedin[3], cachedin[2], cachedin[1], cachedin[0] }; // Data from memory
				ddr3tags[cline] <= ctag;
				ddr3valid[cline] <= 1'b1;
				cachestate <= CUPDATEDELAY;
			end

			default: begin // CUPDATEDELAY
				if (rwmode == 2'b01) begin // Write
					cachestate <= CWRITE;
				end else begin /*if (rwmode == 2'b10) // Read*/
					cachestate <= CREAD;
				end
			end
		endcase
	end
end

endmodule
