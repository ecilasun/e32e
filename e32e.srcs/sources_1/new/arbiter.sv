`timescale 1ns / 1ps

module arbiter(
	input wire aclk,
	input wire aresetn,
	axi_if.slave M[7:0],
	axi_if.master S );

typedef enum logic [3:0] {INIT, ARBITRATE, GRANTED} arbiterstatetype;
arbiterstatetype arbiterstate = INIT, nextarbiterstate = INIT;

logic m0valid = 0;
logic m1valid = 0;
logic m2valid = 0;
logic m3valid = 0;
logic m4valid = 0;
logic m5valid = 0;
logic m6valid = 0;
logic m7valid = 0;
logic shuffle = 0;
logic svalid = 0;

always_comb begin
	m0valid = M[0].arvalid || M[0].awvalid;
	m1valid = M[1].arvalid || M[1].awvalid;
	m2valid = M[2].arvalid || M[2].awvalid;
	m3valid = M[3].arvalid || M[3].awvalid;
	m4valid = M[4].arvalid || M[4].awvalid;
	m5valid = M[5].arvalid || M[5].awvalid;
	m6valid = M[6].arvalid || M[6].awvalid;
	m7valid = M[7].arvalid || M[7].awvalid;
	svalid = (S.rvalid && S.rlast) || S.bvalid;
end

logic [7:0] grant = 8'b00000000;

always_ff @(posedge aclk) begin
	if (~aresetn) begin
		grant = 0;
		shuffle = 0;
	end else begin
		if (arbiterstate == ARBITRATE) begin // Available next clock (in GRANT state)
			if (shuffle)
				grant <= m7valid ? 8'b00000001 : (m6valid ? 8'b00000010 : (m5valid ? 8'b00000100 : (m4valid ? 8'b00001000 : (m3valid ? 8'b00010000 : (m2valid ? 8'b00100000 : (m1valid ? 8'b01000000 : (m0valid ? 8'b10000000 : 8'b00000000)))))));
			else
				grant <= m0valid ? 8'b10000000 : (m1valid ? 8'b01000000 : (m2valid ? 8'b00100000 : (m3valid ? 8'b00010000 : (m4valid ? 8'b00001000 : (m5valid ? 8'b00000100 : (m6valid ? 8'b00000010 : (m7valid ? 8'b00000001 : 8'b00000000)))))));
		end else begin
			// Shuffle the priority between two ends of the request line,
			// effectively reversing the order in which units are granted bus access.
			shuffle <= svalid ? ~shuffle : shuffle;
		end
	end
end

always_comb begin
	M[0].arready = grant == 8'b10000000 ? S.arready : 0;
	M[0].rdata   = grant == 8'b10000000 ? S.rdata : 'dz;
	M[0].rresp   = grant == 8'b10000000 ? S.rresp : 0;
	M[0].rvalid  = grant == 8'b10000000 ? S.rvalid : 0;
	M[0].rlast   = grant == 8'b10000000 ? S.rlast : 0;
	M[0].awready = grant == 8'b10000000 ? S.awready : 0;
	M[0].wready  = grant == 8'b10000000 ? S.wready : 0;
	M[0].bresp   = grant == 8'b10000000 ? S.bresp : 0;
	M[0].bvalid  = grant == 8'b10000000 ? S.bvalid : 0;
	M[1].arready = grant == 8'b01000000 ? S.arready : 0;
	M[1].rdata   = grant == 8'b01000000 ? S.rdata : 'dz;
	M[1].rresp   = grant == 8'b01000000 ? S.rresp : 0;
	M[1].rvalid  = grant == 8'b01000000 ? S.rvalid : 0;
	M[1].rlast   = grant == 8'b01000000 ? S.rlast : 0;
	M[1].awready = grant == 8'b01000000 ? S.awready : 0;
	M[1].wready  = grant == 8'b01000000 ? S.wready : 0;
	M[1].bresp   = grant == 8'b01000000 ? S.bresp : 0;
	M[1].bvalid  = grant == 8'b01000000 ? S.bvalid : 0;
	M[2].arready = grant == 8'b00100000 ? S.arready : 0;
	M[2].rdata   = grant == 8'b00100000 ? S.rdata : 'dz;
	M[2].rresp   = grant == 8'b00100000 ? S.rresp : 0;
	M[2].rvalid  = grant == 8'b00100000 ? S.rvalid : 0;
	M[2].rlast   = grant == 8'b00100000 ? S.rlast : 0;
	M[2].awready = grant == 8'b00100000 ? S.awready : 0;
	M[2].wready  = grant == 8'b00100000 ? S.wready : 0;
	M[2].bresp   = grant == 8'b00100000 ? S.bresp : 0;
	M[2].bvalid  = grant == 8'b00100000 ? S.bvalid : 0;
	M[3].arready = grant == 8'b00010000 ? S.arready : 0;
	M[3].rdata   = grant == 8'b00010000 ? S.rdata : 'dz;
	M[3].rresp   = grant == 8'b00010000 ? S.rresp : 0;
	M[3].rvalid  = grant == 8'b00010000 ? S.rvalid : 0;
	M[3].rlast   = grant == 8'b00010000 ? S.rlast : 0;
	M[3].awready = grant == 8'b00010000 ? S.awready : 0;
	M[3].wready  = grant == 8'b00010000 ? S.wready : 0;
	M[3].bresp   = grant == 8'b00010000 ? S.bresp : 0;
	M[3].bvalid  = grant == 8'b00010000 ? S.bvalid : 0;
	M[4].arready = grant == 8'b00001000 ? S.arready : 0;
	M[4].rdata   = grant == 8'b00001000 ? S.rdata : 'dz;
	M[4].rresp   = grant == 8'b00001000 ? S.rresp : 0;
	M[4].rvalid  = grant == 8'b00001000 ? S.rvalid : 0;
	M[4].rlast   = grant == 8'b00001000 ? S.rlast : 0;
	M[4].awready = grant == 8'b00001000 ? S.awready : 0;
	M[4].wready  = grant == 8'b00001000 ? S.wready : 0;
	M[4].bresp   = grant == 8'b00001000 ? S.bresp : 0;
	M[4].bvalid  = grant == 8'b00001000 ? S.bvalid : 0;
	M[5].arready = grant == 8'b00000100 ? S.arready : 0;
	M[5].rdata   = grant == 8'b00000100 ? S.rdata : 'dz;
	M[5].rresp   = grant == 8'b00000100 ? S.rresp : 0;
	M[5].rvalid  = grant == 8'b00000100 ? S.rvalid : 0;
	M[5].rlast   = grant == 8'b00000100 ? S.rlast : 0;
	M[5].awready = grant == 8'b00000100 ? S.awready : 0;
	M[5].wready  = grant == 8'b00000100 ? S.wready : 0;
	M[5].bresp   = grant == 8'b00000100 ? S.bresp : 0;
	M[5].bvalid  = grant == 8'b00000100 ? S.bvalid : 0;
	M[6].arready = grant == 8'b00000010 ? S.arready : 0;
	M[6].rdata   = grant == 8'b00000010 ? S.rdata : 'dz;
	M[6].rresp   = grant == 8'b00000010 ? S.rresp : 0;
	M[6].rvalid  = grant == 8'b00000010 ? S.rvalid : 0;
	M[6].rlast   = grant == 8'b00000010 ? S.rlast : 0;
	M[6].awready = grant == 8'b00000010 ? S.awready : 0;
	M[6].wready  = grant == 8'b00000010 ? S.wready : 0;
	M[6].bresp   = grant == 8'b00000010 ? S.bresp : 0;
	M[6].bvalid  = grant == 8'b00000010 ? S.bvalid : 0;
	M[7].arready = grant == 8'b00000001 ? S.arready : 0;
	M[7].rdata   = grant == 8'b00000001 ? S.rdata : 'dz;
	M[7].rresp   = grant == 8'b00000001 ? S.rresp : 0;
	M[7].rvalid  = grant == 8'b00000001 ? S.rvalid : 0;
	M[7].rlast   = grant == 8'b00000001 ? S.rlast : 0;
	M[7].awready = grant == 8'b00000001 ? S.awready : 0;
	M[7].wready  = grant == 8'b00000001 ? S.wready : 0;
	M[7].bresp   = grant == 8'b00000001 ? S.bresp : 0;
	M[7].bvalid  = grant == 8'b00000001 ? S.bvalid : 0;
end

always_comb begin
	if (grant == 8'b00000001) begin
		S.araddr	= M[7].araddr;
		S.arvalid	= M[7].arvalid;
		S.arlen		= M[7].arlen;
		S.arsize	= M[7].arsize;
		S.arburst	= M[7].arburst;
		S.rready	= M[7].rready;
		S.awaddr	= M[7].awaddr;
		S.awvalid	= M[7].awvalid;
		S.awlen		= M[7].awlen;
		S.awsize	= M[7].awsize;
		S.awburst	= M[7].awburst;
		S.wdata		= M[7].wdata;
		S.wstrb		= M[7].wstrb;
		S.wvalid	= M[7].wvalid;
		S.wlast		= M[7].wlast;
		S.bready	= M[7].bready;
	end else if (grant == 8'b00000010) begin
		S.araddr	= M[6].araddr;
		S.arvalid	= M[6].arvalid;
		S.arlen		= M[6].arlen;
		S.arsize	= M[6].arsize;
		S.arburst	= M[6].arburst;
		S.rready	= M[6].rready;
		S.awaddr	= M[6].awaddr;
		S.awvalid	= M[6].awvalid;
		S.awlen		= M[6].awlen;
		S.awsize	= M[6].awsize;
		S.awburst	= M[6].awburst;
		S.wdata		= M[6].wdata;
		S.wstrb		= M[6].wstrb;
		S.wvalid	= M[6].wvalid;
		S.wlast		= M[6].wlast;
		S.bready	= M[6].bready;
	end else if (grant == 8'b00000100) begin
		S.araddr	= M[5].araddr;
		S.arvalid	= M[5].arvalid;
		S.arlen		= M[5].arlen;
		S.arsize	= M[5].arsize;
		S.arburst	= M[5].arburst;
		S.rready	= M[5].rready;
		S.awaddr	= M[5].awaddr;
		S.awvalid	= M[5].awvalid;
		S.awlen		= M[5].awlen;
		S.awsize	= M[5].awsize;
		S.awburst	= M[5].awburst;
		S.wdata		= M[5].wdata;
		S.wstrb		= M[5].wstrb;
		S.wvalid	= M[5].wvalid;
		S.wlast		= M[5].wlast;
		S.bready	= M[5].bready;
	end else if (grant == 8'b00001000) begin
		S.araddr	= M[4].araddr;
		S.arvalid	= M[4].arvalid;
		S.arlen		= M[4].arlen;
		S.arsize	= M[4].arsize;
		S.arburst	= M[4].arburst;
		S.rready	= M[4].rready;
		S.awaddr	= M[4].awaddr;
		S.awvalid	= M[4].awvalid;
		S.awlen		= M[4].awlen;
		S.awsize	= M[4].awsize;
		S.awburst	= M[4].awburst;
		S.wdata		= M[4].wdata;
		S.wstrb		= M[4].wstrb;
		S.wvalid	= M[4].wvalid;
		S.wlast		= M[4].wlast;
		S.bready	= M[4].bready;
	end else if (grant == 8'b00010000) begin
		S.araddr	= M[3].araddr;
		S.arvalid	= M[3].arvalid;
		S.arlen		= M[3].arlen;
		S.arsize	= M[3].arsize;
		S.arburst	= M[3].arburst;
		S.rready 	= M[3].rready;
		S.awaddr	= M[3].awaddr;
		S.awvalid	= M[3].awvalid;
		S.awlen		= M[3].awlen;
		S.awsize	= M[3].awsize;
		S.awburst	= M[3].awburst;
		S.wdata		= M[3].wdata;
		S.wstrb		= M[3].wstrb;
		S.wvalid	= M[3].wvalid;
		S.wlast		= M[3].wlast;
		S.bready	= M[3].bready;
	end else if (grant == 8'b00100000) begin
		S.araddr	= M[2].araddr;
		S.arvalid	= M[2].arvalid;
		S.arlen		= M[2].arlen;
		S.arsize	= M[2].arsize;
		S.arburst	= M[2].arburst;
		S.rready	= M[2].rready;
		S.awaddr	= M[2].awaddr;
		S.awvalid	= M[2].awvalid;
		S.awlen		= M[2].awlen;
		S.awsize	= M[2].awsize;
		S.awburst	= M[2].awburst;
		S.wdata		= M[2].wdata;
		S.wstrb		= M[2].wstrb;
		S.wvalid	= M[2].wvalid;
		S.wlast		= M[2].wlast;
		S.bready	= M[2].bready;
	end else if (grant == 8'b01000000) begin
		S.araddr	= M[1].araddr;
		S.arvalid	= M[1].arvalid;
		S.arlen		= M[1].arlen;
		S.arsize	= M[1].arsize;
		S.arburst	= M[1].arburst;
		S.rready	= M[1].rready;
		S.awaddr	= M[1].awaddr;
		S.awvalid	= M[1].awvalid;
		S.awlen		= M[1].awlen;
		S.awsize	= M[1].awsize;
		S.awburst	= M[1].awburst;
		S.wdata		= M[1].wdata;
		S.wstrb		= M[1].wstrb;
		S.wvalid	= M[1].wvalid;
		S.wlast		= M[1].wlast;
		S.bready	= M[1].bready;
	end else if (grant == 8'b10000000) begin
		S.araddr	= M[0].araddr;
		S.arvalid	= M[0].arvalid;
		S.arlen		= M[0].arlen;
		S.arsize	= M[0].arsize;
		S.arburst	= M[0].arburst;
		S.rready	= M[0].rready;
		S.awaddr	= M[0].awaddr;
		S.awvalid	= M[0].awvalid;
		S.awlen		= M[0].awlen;
		S.awsize	= M[0].awsize;
		S.awburst	= M[0].awburst;
		S.wdata		= M[0].wdata;
		S.wstrb		= M[0].wstrb;
		S.wvalid	= M[0].wvalid;
		S.wlast		= M[0].wlast;
		S.bready	= M[0].bready;
	end else begin
		S.araddr	= 0;
		S.arvalid	= 0;
		S.arlen		= 0;
		S.arsize	= 0;
		S.arburst	= 0;
		S.rready	= 0;
		S.awaddr	= 0;
		S.awvalid	= 0;
		S.awlen		= 0;
		S.awsize	= 0;
		S.awburst	= 0;
		S.wdata		= 'dz;
		S.wstrb		= 0;
		S.wvalid	= 0;
		S.wlast		= 0;
		S.bready	= 0;
	end
end

always_ff @(posedge aclk) begin
	if (~aresetn) begin
		arbiterstate <= INIT;
	end else begin
		arbiterstate <= nextarbiterstate;
	end
end

always_comb begin
	case (arbiterstate)
		INIT: begin
			nextarbiterstate = ARBITRATE;
		end

		ARBITRATE: begin
			nextarbiterstate = |{m0valid, m1valid, m2valid, m3valid, m4valid, m5valid, m6valid, m7valid} ? GRANTED : ARBITRATE;
		end

		default/*GRANTED*/: begin
			nextarbiterstate = svalid ? ARBITRATE : GRANTED;
		end
	endcase
end

endmodule
