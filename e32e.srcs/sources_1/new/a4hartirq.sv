`timescale 1ns / 1ps

module axi4hartirq (
	input wire aclk,
	input wire aresetn,
	axi_if.slave s_axi,
	output logic [15:0] hirq );

// IRQ signal register
// Invoker writes, responder clears
// This will hold IRQ high as long as
// the responder leaves the bit untouched
logic [15:0] hartIRQState = 16'h0000;

// Delay one clock
always @(posedge aclk) begin
	hirq <= hartIRQState;
end

logic [1:0] waddrstate = 2'b00;
logic [1:0] writestate = 2'b00;
logic [1:0] raddrstate = 2'b00;

always @(posedge aclk) begin
	if (~aresetn) begin
		s_axi.awready <= 1'b0;
	end else begin
		// write address
		case (waddrstate)
			2'b00: begin
				if (s_axi.awvalid) begin
					s_axi.awready <= 1'b1;
					waddrstate <= 2'b01;
				end
			end
			default/*2'b01*/: begin
				s_axi.awready <= 1'b0;
				waddrstate <= 2'b00;
			end
		endcase
	end
end

always @(posedge aclk) begin
	if (~aresetn) begin
		s_axi.bresp <= 2'b00; // okay
		s_axi.bvalid <= 1'b0;
		s_axi.wready <= 1'b0;
	end else begin
		// write data
		s_axi.wready <= 1'b0;
		s_axi.bvalid <= 1'b0;
		case (writestate)
			2'b00: begin
				if (s_axi.wvalid) begin
					// Only lsb is written
					hartIRQState[s_axi.awaddr[3:0]] <= s_axi.wdata[0];
					writestate <= 2'b01;
					s_axi.wready <= 1'b1;
				end
			end
			default/*2'b01*/: begin
				if (s_axi.bready) begin
					s_axi.bvalid <= 1'b1;
					writestate <= 2'b00;
				end
			end
		endcase
	end
end

always @(posedge aclk) begin
	if (~aresetn) begin
		s_axi.rlast <= 1'b1;
		s_axi.arready <= 1'b0;
		s_axi.rvalid <= 1'b0;
		s_axi.rresp <= 2'b00;
	end else begin
		s_axi.rvalid <= 1'b0;
		s_axi.arready <= 1'b0;
		case (raddrstate)
			2'b00: begin
				if (s_axi.arvalid) begin
					s_axi.arready <= 1'b1;
					raddrstate <= 2'b01;
				end
			end
			default/*2'b01*/: begin
				// Only lsb is returned
				// NOTE: Need to repeat the byte at each offset due to address alignment picking the right one from inside the word (this device is byte aligned with 16 viable offsets)
				s_axi.rdata[31:0] <= {7'd0,hartIRQState[s_axi.araddr[3:0]], 7'd0,hartIRQState[s_axi.araddr[3:0]], 7'd0,hartIRQState[s_axi.araddr[3:0]], 7'd0,hartIRQState[s_axi.araddr[3:0]]};
				s_axi.rvalid <= 1'b1;
				raddrstate <= 2'b00;
			end
		endcase
	end
end

endmodule
