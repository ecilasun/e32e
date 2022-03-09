`timescale 1ns / 1ps

module arbiter(
	input wire aclk,
	input wire aresetn,
	axi_if.slave M[3:0],
	axi_if.master S );

typedef enum logic [3:0] {INIT, ARBITRATE, GRANTED} arbiterstatetype;
arbiterstatetype arbiterstate = INIT, nextarbiterstate = INIT;

logic m0valid = 0;
logic m1valid = 0;
logic m2valid = 0;
logic m3valid = 0;
logic svalid = 0;

always_comb begin
	m0valid = M[0].arvalid || M[0].awvalid;
	m1valid = M[1].arvalid || M[1].awvalid;
	m2valid = M[2].arvalid || M[2].awvalid;
	m3valid = M[3].arvalid || M[3].awvalid;
	svalid = (S.rvalid && S.rlast) || S.bvalid;
end

logic [1:0] sel_m = 2'd0;

always_ff @(posedge aclk) begin
	if (~aresetn) begin
		sel_m = 0;
	end else begin
		if (arbiterstate == ARBITRATE) // Available next clock (in GRANT state)
			sel_m <= m0valid ? 2'd0 : (m1valid ? 2'd1 : (m2valid ? 2'd2 : (m3valid ? 2'd3 : 2'd0)));
	end
end

always_comb begin
	if(arbiterstate == GRANTED) begin
		M[0].arready = sel_m == 0 ? S.arready : 0;
		M[0].rdata   = sel_m == 0 ? S.rdata : 0;
		M[0].rresp   = sel_m == 0 ? S.rresp : 0;
		M[0].rvalid  = sel_m == 0 ? S.rvalid : 0;
		M[0].rlast   = sel_m == 0 ? S.rlast : 0;
		M[0].awready = sel_m == 0 ? S.awready : 0;
		M[0].wready  = sel_m == 0 ? S.wready : 0;
		M[0].bresp   = sel_m == 0 ? S.bresp : 0;
		M[0].bvalid  = sel_m == 0 ? S.bvalid : 0;
		M[1].arready = sel_m == 1 ? S.arready : 0;
		M[1].rdata   = sel_m == 1 ? S.rdata : 0;
		M[1].rresp   = sel_m == 1 ? S.rresp : 0;
		M[1].rvalid  = sel_m == 1 ? S.rvalid : 0;
		M[1].rlast   = sel_m == 1 ? S.rlast : 0;
		M[1].awready = sel_m == 1 ? S.awready : 0;
		M[1].wready  = sel_m == 1 ? S.wready : 0;
		M[1].bresp   = sel_m == 1 ? S.bresp : 0;
		M[1].bvalid  = sel_m == 1 ? S.bvalid : 0;
		M[2].arready = sel_m == 2 ? S.arready : 0;
		M[2].rdata   = sel_m == 2 ? S.rdata : 0;
		M[2].rresp   = sel_m == 2 ? S.rresp : 0;
		M[2].rvalid  = sel_m == 2 ? S.rvalid : 0;
		M[2].rlast   = sel_m == 2 ? S.rlast : 0;
		M[2].awready = sel_m == 2 ? S.awready : 0;
		M[2].wready  = sel_m == 2 ? S.wready : 0;
		M[2].bresp   = sel_m == 2 ? S.bresp : 0;
		M[2].bvalid  = sel_m == 2 ? S.bvalid : 0;
		M[3].arready = sel_m == 3 ? S.arready : 0;
		M[3].rdata   = sel_m == 3 ? S.rdata : 0;
		M[3].rresp   = sel_m == 3 ? S.rresp : 0;
		M[3].rvalid  = sel_m == 3 ? S.rvalid : 0;
		M[3].rlast   = sel_m == 3 ? S.rlast : 0;
		M[3].awready = sel_m == 3 ? S.awready : 0;
		M[3].wready  = sel_m == 3 ? S.wready : 0;
		M[3].bresp   = sel_m == 3 ? S.bresp : 0;
		M[3].bvalid  = sel_m == 3 ? S.bvalid : 0;
	end else begin
		M[0].arready = 0;
		M[0].rdata = 0;
		M[0].rresp = 0;
		M[0].rvalid = 0;
		M[0].rlast = 0;
		M[0].awready = 0;
		M[0].wready = 0;
		M[0].bresp = 0;
		M[0].bvalid = 0;
		M[1].arready = 0;
		M[1].rdata = 0;
		M[1].rresp = 0;
		M[1].rvalid = 0;
		M[1].rlast = 0;
		M[1].awready = 0;
		M[1].wready = 0;
		M[1].bresp = 0;
		M[1].bvalid = 0;
		M[2].arready = 0;
		M[2].rdata = 0;
		M[2].rresp = 0;
		M[2].rvalid = 0;
		M[2].rlast = 0;
		M[2].awready = 0;
		M[2].wready = 0;
		M[2].bresp = 0;
		M[2].bvalid = 0;
		M[3].arready = 0;
		M[3].rdata = 0;
		M[3].rresp = 0;
		M[3].rvalid = 0;
		M[3].rlast = 0;
		M[3].awready = 0;
		M[3].wready = 0;
		M[3].bresp = 0;
		M[3].bvalid = 0;
	end
end

always_comb begin
	if (arbiterstate == GRANTED) begin
		if (sel_m == 2'd3) begin
			S.araddr = M[3].araddr;
			S.arvalid = M[3].arvalid;
			S.arlen = M[3].arlen;
			S.arsize = M[3].arsize;
			S.arburst = M[3].arburst;
			S.rready = M[3].rready;
			S.awaddr = M[3].awaddr;
			S.awvalid = M[3].awvalid;
			S.awlen = M[3].awlen;
			S.awsize = M[3].awsize;
			S.awburst = M[3].awburst;
			S.wdata = M[3].wdata;
			S.wstrb = M[3].wstrb;
			S.wvalid = M[3].wvalid;
			S.wlast = M[3].wlast;
			S.bready = M[3].bready;
		end else if (sel_m == 2'd2) begin
			S.araddr = M[2].araddr;
			S.arvalid = M[2].arvalid;
			S.arlen = M[2].arlen;
			S.arsize = M[2].arsize;
			S.arburst = M[2].arburst;
			S.rready = M[2].rready;
			S.awaddr = M[2].awaddr;
			S.awvalid = M[2].awvalid;
			S.awlen = M[2].awlen;
			S.awsize = M[2].awsize;
			S.awburst = M[2].awburst;
			S.wdata = M[2].wdata;
			S.wstrb = M[2].wstrb;
			S.wvalid = M[2].wvalid;
			S.wlast = M[2].wlast;
			S.bready = M[2].bready;
		end else if (sel_m == 2'd1) begin
			S.araddr = M[1].araddr;
			S.arvalid = M[1].arvalid;
			S.arlen = M[1].arlen;
			S.arsize = M[1].arsize;
			S.arburst = M[1].arburst;
			S.rready = M[1].rready;
			S.awaddr = M[1].awaddr;
			S.awvalid = M[1].awvalid;
			S.awlen = M[1].awlen;
			S.awsize = M[1].awsize;
			S.awburst = M[1].awburst;
			S.wdata = M[1].wdata;
			S.wstrb = M[1].wstrb;
			S.wvalid = M[1].wvalid;
			S.wlast = M[1].wlast;
			S.bready = M[1].bready;
		end else begin // sel_m == 2'd0
			S.araddr = M[0].araddr;
			S.arvalid = M[0].arvalid;
			S.arlen = M[0].arlen;
			S.arsize = M[0].arsize;
			S.arburst = M[0].arburst;
			S.rready = M[0].rready;
			S.awaddr = M[0].awaddr;
			S.awvalid = M[0].awvalid;
			S.awlen = M[0].awlen;
			S.awsize = M[0].awsize;
			S.awburst = M[0].awburst;
			S.wdata = M[0].wdata;
			S.wstrb = M[0].wstrb;
			S.wvalid = M[0].wvalid;
			S.wlast = M[0].wlast;
			S.bready = M[0].bready;
		end
	end else begin
		S.araddr = 0;
		S.arvalid = 0;
		S.arlen = 0;
		S.arsize = 0;
		S.arburst = 0;
		S.rready = 0;
		S.awaddr = 0;
		S.awvalid = 0;
		S.awlen = 0;
		S.awsize = 0;
		S.awburst = 0;
		S.wdata = 0;
		S.wstrb = 0;
		S.wvalid = 0;
		S.wlast = 0;
		S.bready = 0;
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
			nextarbiterstate = (m0valid || m1valid || m2valid || m3valid) ? GRANTED : ARBITRATE;
		end

		default/*GRANTED*/: begin
			nextarbiterstate = svalid ? ARBITRATE : GRANTED;
		end
	endcase
end

endmodule
