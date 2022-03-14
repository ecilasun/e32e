`timescale 1ns / 1ps

module clockandreset(
	input wire calib_done,
	input wire sys_clock_i,
	output wire busclock,
	output wire wallclock,
	output wire uartbaseclock,
	output wire pixelclock,
	output wire videoclock,
	output wire hidclock,
	output wire clk_sys_i,
	output wire clk_ref_i,
	output logic selfresetn,
	output wire aresetn );

wire centralclocklocked, peripheralclklocked, ddr3clklocked;

centralclockgen centralclock(
	.clk_in1(sys_clock_i),
	.busclock(busclock),
	.wallclock(wallclock),
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
	.uartbaseclock(uartbaseclock),
	.hidclock(hidclock),
	.locked(peripheralclklocked) );

// Hold reset until clocks are locked
wire internalreset = ~(centralclocklocked & peripheralclklocked & ddr3clklocked);

// delayed reset post-clock-lock
logic [3:0] resetcountdown = 4'hf;
always @(posedge wallclock) begin // using slowest clock
	if (internalreset) begin
		resetcountdown <= 4'hf;
		selfresetn <= 1'b0;
	end else begin
		if (/*busready &&*/ (resetcountdown == 4'h0))
			selfresetn <= 1'b1;
		else
			resetcountdown <= resetcountdown - 4'h1;
	end
end

assign aresetn = selfresetn ? calib_done : 1'b0;

endmodule
