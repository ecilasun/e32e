`timescale 1ns / 1ps

module clockandreset(
	input wire calib_done,
	input wire sys_clock_i,
	output wire busclock,
	output wire wallclock,
	output wire uartbaseclock,
	output wire spibaseclock,
	output wire pixelclock,
	output wire videoclock,
	output wire hidclock,
	output wire clk_sys_i,
	output wire clk_ref_i,
	output wire audioclock,
	output wire selfresetn,
	output wire aresetn );

wire centralclocklocked, peripheralclklocked, ddr3clklocked;

(* async_reg = "true" *) logic calibA = 1'b0;
(* async_reg = "true" *) logic calibB = 1'b0;
always @(posedge wallclock) begin
	calibA <= calib_done;
	calibB <= calibA;
end

(* async_reg = "true" *) logic regaresetn = 1'b0;
assign aresetn = regaresetn ? calibB : 1'b0;
assign selfresetn = regaresetn;

centralclockgen centralclock(
	.clk_in1(sys_clock_i),
	.busclock(busclock),
	.wallclock(wallclock),
	.spibaseclock(spibaseclock),
	.locked(centralclocklocked) );

ddr3clk ddr3memoryclock(
	.clk_in1(sys_clock_i),
	.clk_sys_i(clk_sys_i),
	.clk_ref_i(clk_ref_i),
	.locked(ddr3clklocked) );

videoclockgen peripheralclock(
	.clk_in1(sys_clock_i),
	.pixelclock(pixelclock),
	.videoclock(videoclock),
	.hidclock(hidclock),
	.uartbaseclock(uartbaseclock),
	.audioclock(audioclock),
	.locked(peripheralclklocked) );

// Hold reset until clocks are locked
wire internalreset = ~(centralclocklocked & peripheralclklocked & ddr3clklocked);
(* async_reg = "true" *) logic resettrigA = 1'b1;
(* async_reg = "true" *) logic resettrigB = 1'b1;

// Delayed reset post-clock-lock
logic [15:0] resetcountdown = 16'h0001;

always @(posedge wallclock) begin
	if (resettrigB) begin
		resetcountdown <= 16'h0001;
		regaresetn <= 1'b0;
	end else begin
		resetcountdown <= {resetcountdown[14:0], 1'b1};
		regaresetn <= resetcountdown[15];
	end
	// DC
	resettrigA <= internalreset;
	resettrigB <= resettrigA;
end

endmodule
