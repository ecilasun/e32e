`timescale 1ns / 1ps

module arbiter(
	input wire aclk,
	input wire aresetn,
	axi_if.slave axi_s[7:0],	// To slave in ports of master devices
	axi_if.master axi_m );		// To master in port of slave device

typedef enum logic [3:0] {INIT, ARBITRATE, GRANTED} arbiterstatetype;
arbiterstatetype arbiterstate = INIT, nextarbiterstate = INIT;

logic [7:0] req;
logic [7:0] grant;
logic reqcomplete = 0;

// A request is considered only when an incoming read or write address is valid
always_comb begin
	req[0] = axi_s[0].arvalid || axi_s[0].awvalid;
	req[1] = axi_s[1].arvalid || axi_s[1].awvalid;
	req[2] = axi_s[2].arvalid || axi_s[2].awvalid;
	req[3] = axi_s[3].arvalid || axi_s[3].awvalid;
	req[4] = axi_s[4].arvalid || axi_s[4].awvalid;
	req[5] = axi_s[5].arvalid || axi_s[5].awvalid;
	req[6] = axi_s[6].arvalid || axi_s[6].awvalid;
	req[7] = axi_s[7].arvalid || axi_s[7].awvalid;
end

// A grant is complete once we get a notification for a read or write completion
always_comb begin
	reqcomplete = (axi_m.rvalid && axi_m.rlast) || axi_m.bvalid;
end

always_ff @(posedge aclk) begin
	if (~aresetn) begin
		grant <= 0;
	end else begin
		// Grant access to the lowest device index requesting (lowest bit)
		grant <= (arbiterstate == ARBITRATE) ? ((~req+1)&req) : grant;
	end
end

genvar gnt;
generate
for (gnt=0; gnt<8; gnt++) begin
	always_comb begin
		axi_s[gnt].arready = grant[gnt] ? axi_m.arready : 0;
		axi_s[gnt].rdata   = grant[gnt] ? axi_m.rdata : 'dz;
		axi_s[gnt].rresp   = grant[gnt] ? axi_m.rresp : 0;
		axi_s[gnt].rvalid  = grant[gnt] ? axi_m.rvalid : 0;
		axi_s[gnt].rlast   = grant[gnt] ? axi_m.rlast : 0;
		axi_s[gnt].awready = grant[gnt] ? axi_m.awready : 0;
		axi_s[gnt].wready  = grant[gnt] ? axi_m.wready : 0;
		axi_s[gnt].bresp   = grant[gnt] ? axi_m.bresp : 0;
		axi_s[gnt].bvalid  = grant[gnt] ? axi_m.bvalid : 0;
	end
end
endgenerate

always_comb begin
	if (grant[7]) begin
		axi_m.araddr	= axi_s[7].araddr;
		axi_m.arvalid	= axi_s[7].arvalid;
		axi_m.arlen		= axi_s[7].arlen;
		axi_m.arsize	= axi_s[7].arsize;
		axi_m.arburst	= axi_s[7].arburst;
		axi_m.rready	= axi_s[7].rready;
		axi_m.awaddr	= axi_s[7].awaddr;
		axi_m.awvalid	= axi_s[7].awvalid;
		axi_m.awlen		= axi_s[7].awlen;
		axi_m.awsize	= axi_s[7].awsize;
		axi_m.awburst	= axi_s[7].awburst;
		axi_m.wdata		= axi_s[7].wdata;
		axi_m.wstrb		= axi_s[7].wstrb;
		axi_m.wvalid	= axi_s[7].wvalid;
		axi_m.wlast		= axi_s[7].wlast;
		axi_m.bready	= axi_s[7].bready;
	end else if (grant[6]) begin
		axi_m.araddr	= axi_s[6].araddr;
		axi_m.arvalid	= axi_s[6].arvalid;
		axi_m.arlen		= axi_s[6].arlen;
		axi_m.arsize	= axi_s[6].arsize;
		axi_m.arburst	= axi_s[6].arburst;
		axi_m.rready	= axi_s[6].rready;
		axi_m.awaddr	= axi_s[6].awaddr;
		axi_m.awvalid	= axi_s[6].awvalid;
		axi_m.awlen		= axi_s[6].awlen;
		axi_m.awsize	= axi_s[6].awsize;
		axi_m.awburst	= axi_s[6].awburst;
		axi_m.wdata		= axi_s[6].wdata;
		axi_m.wstrb		= axi_s[6].wstrb;
		axi_m.wvalid	= axi_s[6].wvalid;
		axi_m.wlast		= axi_s[6].wlast;
		axi_m.bready	= axi_s[6].bready;
	end else if (grant[5]) begin
		axi_m.araddr	= axi_s[5].araddr;
		axi_m.arvalid	= axi_s[5].arvalid;
		axi_m.arlen		= axi_s[5].arlen;
		axi_m.arsize	= axi_s[5].arsize;
		axi_m.arburst	= axi_s[5].arburst;
		axi_m.rready	= axi_s[5].rready;
		axi_m.awaddr	= axi_s[5].awaddr;
		axi_m.awvalid	= axi_s[5].awvalid;
		axi_m.awlen		= axi_s[5].awlen;
		axi_m.awsize	= axi_s[5].awsize;
		axi_m.awburst	= axi_s[5].awburst;
		axi_m.wdata		= axi_s[5].wdata;
		axi_m.wstrb		= axi_s[5].wstrb;
		axi_m.wvalid	= axi_s[5].wvalid;
		axi_m.wlast		= axi_s[5].wlast;
		axi_m.bready	= axi_s[5].bready;
	end else if (grant[4]) begin
		axi_m.araddr	= axi_s[4].araddr;
		axi_m.arvalid	= axi_s[4].arvalid;
		axi_m.arlen		= axi_s[4].arlen;
		axi_m.arsize	= axi_s[4].arsize;
		axi_m.arburst	= axi_s[4].arburst;
		axi_m.rready	= axi_s[4].rready;
		axi_m.awaddr	= axi_s[4].awaddr;
		axi_m.awvalid	= axi_s[4].awvalid;
		axi_m.awlen		= axi_s[4].awlen;
		axi_m.awsize	= axi_s[4].awsize;
		axi_m.awburst	= axi_s[4].awburst;
		axi_m.wdata		= axi_s[4].wdata;
		axi_m.wstrb		= axi_s[4].wstrb;
		axi_m.wvalid	= axi_s[4].wvalid;
		axi_m.wlast		= axi_s[4].wlast;
		axi_m.bready	= axi_s[4].bready;
	end else if (grant[3]) begin
		axi_m.araddr	= axi_s[3].araddr;
		axi_m.arvalid	= axi_s[3].arvalid;
		axi_m.arlen		= axi_s[3].arlen;
		axi_m.arsize	= axi_s[3].arsize;
		axi_m.arburst	= axi_s[3].arburst;
		axi_m.rready 	= axi_s[3].rready;
		axi_m.awaddr	= axi_s[3].awaddr;
		axi_m.awvalid	= axi_s[3].awvalid;
		axi_m.awlen		= axi_s[3].awlen;
		axi_m.awsize	= axi_s[3].awsize;
		axi_m.awburst	= axi_s[3].awburst;
		axi_m.wdata		= axi_s[3].wdata;
		axi_m.wstrb		= axi_s[3].wstrb;
		axi_m.wvalid	= axi_s[3].wvalid;
		axi_m.wlast		= axi_s[3].wlast;
		axi_m.bready	= axi_s[3].bready;
	end else if (grant[2]) begin
		axi_m.araddr	= axi_s[2].araddr;
		axi_m.arvalid	= axi_s[2].arvalid;
		axi_m.arlen		= axi_s[2].arlen;
		axi_m.arsize	= axi_s[2].arsize;
		axi_m.arburst	= axi_s[2].arburst;
		axi_m.rready	= axi_s[2].rready;
		axi_m.awaddr	= axi_s[2].awaddr;
		axi_m.awvalid	= axi_s[2].awvalid;
		axi_m.awlen		= axi_s[2].awlen;
		axi_m.awsize	= axi_s[2].awsize;
		axi_m.awburst	= axi_s[2].awburst;
		axi_m.wdata		= axi_s[2].wdata;
		axi_m.wstrb		= axi_s[2].wstrb;
		axi_m.wvalid	= axi_s[2].wvalid;
		axi_m.wlast		= axi_s[2].wlast;
		axi_m.bready	= axi_s[2].bready;
	end else if (grant[1]) begin
		axi_m.araddr	= axi_s[1].araddr;
		axi_m.arvalid	= axi_s[1].arvalid;
		axi_m.arlen		= axi_s[1].arlen;
		axi_m.arsize	= axi_s[1].arsize;
		axi_m.arburst	= axi_s[1].arburst;
		axi_m.rready	= axi_s[1].rready;
		axi_m.awaddr	= axi_s[1].awaddr;
		axi_m.awvalid	= axi_s[1].awvalid;
		axi_m.awlen		= axi_s[1].awlen;
		axi_m.awsize	= axi_s[1].awsize;
		axi_m.awburst	= axi_s[1].awburst;
		axi_m.wdata		= axi_s[1].wdata;
		axi_m.wstrb		= axi_s[1].wstrb;
		axi_m.wvalid	= axi_s[1].wvalid;
		axi_m.wlast		= axi_s[1].wlast;
		axi_m.bready	= axi_s[1].bready;
	end else if (grant[0]) begin
		axi_m.araddr	= axi_s[0].araddr;
		axi_m.arvalid	= axi_s[0].arvalid;
		axi_m.arlen		= axi_s[0].arlen;
		axi_m.arsize	= axi_s[0].arsize;
		axi_m.arburst	= axi_s[0].arburst;
		axi_m.rready	= axi_s[0].rready;
		axi_m.awaddr	= axi_s[0].awaddr;
		axi_m.awvalid	= axi_s[0].awvalid;
		axi_m.awlen		= axi_s[0].awlen;
		axi_m.awsize	= axi_s[0].awsize;
		axi_m.awburst	= axi_s[0].awburst;
		axi_m.wdata		= axi_s[0].wdata;
		axi_m.wstrb		= axi_s[0].wstrb;
		axi_m.wvalid	= axi_s[0].wvalid;
		axi_m.wlast		= axi_s[0].wlast;
		axi_m.bready	= axi_s[0].bready;
	end else begin
		axi_m.araddr	= 0;
		axi_m.arvalid	= 0;
		axi_m.arlen		= 0;
		axi_m.arsize	= 0;
		axi_m.arburst	= 0;
		axi_m.rready	= 0;
		axi_m.awaddr	= 0;
		axi_m.awvalid	= 0;
		axi_m.awlen		= 0;
		axi_m.awsize	= 0;
		axi_m.awburst	= 0;
		axi_m.wdata		= 'dz;
		axi_m.wstrb		= 0;
		axi_m.wvalid	= 0;
		axi_m.wlast		= 0;
		axi_m.bready	= 0;
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
			nextarbiterstate = (|req) ? GRANTED : ARBITRATE;
		end

		default/*GRANTED*/: begin
			nextarbiterstate = reqcomplete ? ARBITRATE : GRANTED;
		end
	endcase
end

endmodule
