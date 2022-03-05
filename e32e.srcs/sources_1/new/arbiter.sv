`timescale 1ns / 1ps

module arbiter(
	input wire aclk,
	input wire aresetn,
	axi_if.slave M[1:0],
	axi_if.master S );

typedef enum logic [3:0] {INIT, IDLE, GRANTED} arbiterstatetype;
arbiterstatetype arbiterstate = INIT, nextarbiterstate = INIT;

logic sel_m = 0;
logic round = 0;

always_comb begin
	if (arbiterstate == GRANTED) begin
		if (sel_m == 0) begin
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
			M[0].arready = S.arready;
			M[0].rdata = S.rdata;
			M[0].rresp = S.rresp;
			M[0].rvalid = S.rvalid;
			M[0].rlast = S.rlast;
			M[0].awready = S.awready;
			M[0].wready = S.wready;
			M[0].bresp = S.bresp;
			M[0].bvalid = S.bvalid;
			M[1].arready = 0;
			M[1].rdata = 0;
			M[1].rresp = 0;
			M[1].rvalid = 0;
			M[1].rlast = 0;
			M[1].awready = 0;
			M[1].wready = 0;
			M[1].bresp = 0;
			M[1].bvalid = 0;
		end else begin
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
			M[1].arready = S.arready;
			M[1].rdata = S.rdata;
			M[1].rresp = S.rresp;
			M[1].rvalid = S.rvalid;
			M[1].rlast = S.rlast;
			M[1].awready = S.awready;
			M[1].wready = S.wready;
			M[1].bresp = S.bresp;
			M[1].bvalid = S.bvalid;
			M[0].arready = 0;
			M[0].rdata = 0;
			M[0].rresp = 0;
			M[0].rvalid = 0;
			M[0].rlast = 0;
			M[0].awready = 0;
			M[0].wready = 0;
			M[0].bresp = 0;
			M[0].bvalid = 0;
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
			nextarbiterstate = IDLE;
		end

		IDLE: begin
			case (round)
				0: begin
					if (M[0].arvalid || M[0].awvalid) begin
						sel_m = 0;
						round = 1;
					end else if (M[1].arvalid || M[1].awvalid) begin
						sel_m = 1;
						round = 0;
					end else begin
						sel_m = 0;
					end
				end
				default: begin
					if (M[1].arvalid || M[1].awvalid) begin
						sel_m = 1;
						round = 0;
					end else if (M[0].arvalid || M[0].awvalid) begin
						sel_m = 0;
						round = 1;
					end else begin
						sel_m = 0;
					end
				end
			endcase
			nextarbiterstate = (M[0].arvalid || M[0].awvalid || M[1].arvalid || M[1].awvalid) ? GRANTED : IDLE;
		end

		default/*GRANTED*/: begin
			nextarbiterstate = ((S.rvalid&&S.rlast) || S.bvalid) ? IDLE : GRANTED;
		end
	endcase
end

endmodule
