`timescale 1ns / 1ps

// Round-robin arbiter for 3 master devices

module ucarbiter(
	input wire aclk,
	input wire aresetn,
	axi_if.slave axi_s[2:0],	// To slave in ports of master devices
	axi_if.master axi_m );	// To master in port of slave device

typedef enum logic [3:0] {INIT, ARBITRATE0, ARBITRATE1, ARBITRATE2, GRANTED} arbiterstatetype;
arbiterstatetype readstate = INIT;
arbiterstatetype rarbstate = ARBITRATE0;
arbiterstatetype writestate = INIT;
arbiterstatetype warbstate = ARBITRATE0;

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

// Read grants
genvar rgnt;
generate
for (rgnt=0; rgnt<3; rgnt++) begin
	always_comb begin
		axi_s[rgnt].arready = rgrant[rgnt] ? axi_m.arready : 0;
		axi_s[rgnt].rdata   = rgrant[rgnt] ? axi_m.rdata : 'dz;
		axi_s[rgnt].rresp   = rgrant[rgnt] ? axi_m.rresp : 0;
		axi_s[rgnt].rvalid  = rgrant[rgnt] ? axi_m.rvalid : 0;
		axi_s[rgnt].rlast   = rgrant[rgnt] ? axi_m.rlast : 0;
	end
end
endgenerate

// Write grants
genvar wgnt;
generate
for (wgnt=0; wgnt<3; wgnt++) begin
	always_comb begin
		axi_s[wgnt].awready = wgrant[wgnt] ? axi_m.awready : 0;
		axi_s[wgnt].wready  = wgrant[wgnt] ? axi_m.wready : 0;
		axi_s[wgnt].bresp   = wgrant[wgnt] ? axi_m.bresp : 0;
		axi_s[wgnt].bvalid  = wgrant[wgnt] ? axi_m.bvalid : 0;
	end
end
endgenerate

always_comb begin
	case (1'b1)
		rgrant[2]: begin
			axi_m.araddr	= axi_s[2].araddr;
			axi_m.arvalid	= axi_s[2].arvalid;
			axi_m.arlen		= axi_s[2].arlen;
			axi_m.arsize	= axi_s[2].arsize;
			axi_m.arburst	= axi_s[2].arburst;
			axi_m.rready	= axi_s[2].rready;
		end
		rgrant[1]: begin
			axi_m.araddr	= axi_s[1].araddr;
			axi_m.arvalid	= axi_s[1].arvalid;
			axi_m.arlen		= axi_s[1].arlen;
			axi_m.arsize	= axi_s[1].arsize;
			axi_m.arburst	= axi_s[1].arburst;
			axi_m.rready	= axi_s[1].rready;
		end
		rgrant[0]: begin
			axi_m.araddr	= axi_s[0].araddr;
			axi_m.arvalid	= axi_s[0].arvalid;
			axi_m.arlen		= axi_s[0].arlen;
			axi_m.arsize	= axi_s[0].arsize;
			axi_m.arburst	= axi_s[0].arburst;
			axi_m.rready	= axi_s[0].rready;
		end
		default: begin
			axi_m.araddr	= 0;
			axi_m.arvalid	= 0;
			axi_m.arlen		= 0;
			axi_m.arsize	= 0;
			axi_m.arburst	= 0;
			axi_m.rready	= 0;
		end
	endcase
end

always_comb begin
	case (1'b1)
		wgrant[2]: begin
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
		end
		wgrant[1]: begin
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
		end
		wgrant[0]: begin
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
		end
		default: begin
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
	endcase
end

always_ff @(posedge aclk) begin
	if (~aresetn) begin
		readstate <= INIT;
		rgrant <= 0;
	end else begin
		case (readstate)
			INIT: begin
				readstate <= ARBITRATE0;
			end

			ARBITRATE0: begin
				readstate <= (|rreq) ? GRANTED : ARBITRATE0;
				priority case(1'b1)
					rreq[1] : begin rgrant <= 3'b010; rarbstate <= ARBITRATE1; end
					rreq[2] : begin rgrant <= 3'b100; rarbstate <= ARBITRATE2; end
					rreq[0] : begin rgrant <= 3'b001; rarbstate <= ARBITRATE0; end
					default : rgrant = 3'b000;
				endcase
			end

			ARBITRATE1: begin
				readstate <= (|rreq) ? GRANTED : ARBITRATE1;
				priority case(1'b1)
					rreq[2] : begin rgrant <= 3'b100; rarbstate <= ARBITRATE2; end
					rreq[0] : begin rgrant <= 3'b001; rarbstate <= ARBITRATE0; end
					rreq[1] : begin rgrant <= 3'b010; rarbstate <= ARBITRATE1; end
					default : rgrant = 3'b000;
				endcase
			end

			ARBITRATE2: begin
				readstate <= (|rreq) ? GRANTED : ARBITRATE2;
				priority case(1'b1)
					rreq[0] : begin rgrant <= 3'b001; rarbstate <= ARBITRATE0; end
					rreq[1] : begin rgrant <= 3'b010; rarbstate <= ARBITRATE1; end
					rreq[2] : begin rgrant <= 3'b100; rarbstate <= ARBITRATE2; end
					default : rgrant = 3'b000;
				endcase
			end

			default: begin // GRANTED
				readstate <= rreqcomplete ? rarbstate : GRANTED;
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
			INIT: begin
				writestate <= ARBITRATE0;
			end

			ARBITRATE0: begin
				writestate <= (|wreq) ? GRANTED : ARBITRATE0;
				priority case(1'b1)
					wreq[1] : begin wgrant <= 3'b010; warbstate <= ARBITRATE1; end
					wreq[2] : begin wgrant <= 3'b100; warbstate <= ARBITRATE2; end
					wreq[0] : begin wgrant <= 3'b001; warbstate <= ARBITRATE0; end
					default : wgrant <= 3'b000;
				endcase
			end

			ARBITRATE1: begin
				writestate <= (|wreq) ? GRANTED : ARBITRATE1;
				priority case(1'b1)
					wreq[2] : begin wgrant <= 3'b100; warbstate <= ARBITRATE2; end
					wreq[0] : begin wgrant <= 3'b001; warbstate <= ARBITRATE0; end
					wreq[1] : begin wgrant <= 3'b010; warbstate <= ARBITRATE1; end
					default : wgrant <= 3'b000;
				endcase
			end

			ARBITRATE2: begin
				writestate <= (|wreq) ? GRANTED : ARBITRATE2;
				priority case(1'b1)
					wreq[0] : begin wgrant <= 3'b001; warbstate <= ARBITRATE0; end
					wreq[1] : begin wgrant <= 3'b010; warbstate <= ARBITRATE1; end
					wreq[2] : begin wgrant <= 3'b100; warbstate <= ARBITRATE2; end
					default : wgrant <= 3'b000;
				endcase
			end

			default: begin // GRANTED
				writestate <= wreqcomplete ? warbstate : GRANTED;
			end
		endcase
	end
end

endmodule
