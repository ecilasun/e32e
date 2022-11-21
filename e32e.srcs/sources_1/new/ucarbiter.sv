`timescale 1ns / 1ps

module ucarbiter(
	input wire aclk,
	input wire aresetn,
	axi_if.slave axi_s[2:0],	// To slave in ports of master devices
	axi_if.master axi_m );		// To master in port of slave device

typedef enum logic [3:0] {INIT, ARBITRATE, GRANTED} arbiterstatetype;
arbiterstatetype readstate = INIT;
arbiterstatetype writestate = INIT;

logic [2:0] rreq;
logic [2:0] rgrant;
logic [2:0] wreq;
logic [2:0] wgrant;
logic rreqcomplete = 0;
logic wreqcomplete = 0;

// A request is considered only when an incoming read or write address is valid
genvar reqgen;
generate
for (reqgen=0; reqgen<3; reqgen++) begin
	always_comb begin
		rreq[reqgen] = axi_s[reqgen].arvalid;
		wreq[reqgen] = axi_s[reqgen].awvalid;
	end
end
endgenerate

// A grant is complete once we get a notification for a read or write completion
always_comb begin
	rreqcomplete = axi_m.rvalid && axi_m.rlast;
	wreqcomplete = axi_m.bvalid;
end

genvar gnt;
generate
for (gnt=0; gnt<3; gnt++) begin
	always_comb begin
		// Read
		axi_s[gnt].arready = rgrant[gnt] ? axi_m.arready : 0;
		axi_s[gnt].rdata   = rgrant[gnt] ? axi_m.rdata : 'dz;
		axi_s[gnt].rresp   = rgrant[gnt] ? axi_m.rresp : 0;
		axi_s[gnt].rvalid  = rgrant[gnt] ? axi_m.rvalid : 0;
		axi_s[gnt].rlast   = rgrant[gnt] ? axi_m.rlast : 0;
		// Write
		axi_s[gnt].awready = wgrant[gnt] ? axi_m.awready : 0;
		axi_s[gnt].wready  = wgrant[gnt] ? axi_m.wready : 0;
		axi_s[gnt].bresp   = wgrant[gnt] ? axi_m.bresp : 0;
		axi_s[gnt].bvalid  = wgrant[gnt] ? axi_m.bvalid : 0;
	end
end
endgenerate

always_comb begin
	if (rgrant[2]) begin
		axi_m.araddr	= axi_s[2].araddr;
		axi_m.arvalid	= axi_s[2].arvalid;
		axi_m.arlen		= axi_s[2].arlen;
		axi_m.arsize	= axi_s[2].arsize;
		axi_m.arburst	= axi_s[2].arburst;
		axi_m.rready	= axi_s[2].rready;
	end else if (rgrant[1]) begin
		axi_m.araddr	= axi_s[1].araddr;
		axi_m.arvalid	= axi_s[1].arvalid;
		axi_m.arlen		= axi_s[1].arlen;
		axi_m.arsize	= axi_s[1].arsize;
		axi_m.arburst	= axi_s[1].arburst;
		axi_m.rready	= axi_s[1].rready;
	end else if (rgrant[0]) begin
		axi_m.araddr	= axi_s[0].araddr;
		axi_m.arvalid	= axi_s[0].arvalid;
		axi_m.arlen		= axi_s[0].arlen;
		axi_m.arsize	= axi_s[0].arsize;
		axi_m.arburst	= axi_s[0].arburst;
		axi_m.rready	= axi_s[0].rready;
	end else begin
		axi_m.araddr	= 0;
		axi_m.arvalid	= 0;
		axi_m.arlen		= 0;
		axi_m.arsize	= 0;
		axi_m.arburst	= 0;
		axi_m.rready	= 0;
	end
end

always_comb begin
	if (wgrant[2]) begin
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
	end else if (wgrant[1]) begin
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
	end else if (wgrant[0]) begin
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
		readstate <= INIT;
		rgrant <= 0;
	end else begin
		case (readstate)
			default: begin // INIT
				readstate <= ARBITRATE;
			end

			ARBITRATE: begin
				readstate <= (|rreq) ? GRANTED : ARBITRATE;
				rgrant <= ((~rreq+1) & rreq);
			end

			GRANTED: begin
				readstate <= rreqcomplete ? ARBITRATE : GRANTED;
			end
		endcase
	end
end

always_ff @(posedge aclk) begin
	if (~aresetn) begin
		writestate <= INIT;
		wgrant <= 0;
	end else begin
		case (writestate)
			default: begin // INIT
				writestate <= ARBITRATE;
			end

			ARBITRATE: begin
				writestate <= (|wreq) ? GRANTED : ARBITRATE;
				wgrant <= ((~wreq+1) & wreq);
			end

			GRANTED: begin
				writestate <= wreqcomplete ? ARBITRATE : GRANTED;
			end
		endcase
	end
end

endmodule
