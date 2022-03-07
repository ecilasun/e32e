`timescale 1ns / 1ps

module clockandreset(
	input wire sys_clock_i,
	output wire busclock,
	output wire wallclock,
	output wire uartbaseclock,
	output wire pixelclock,
	output wire videoclock,
	//output wire clk_sys_i,
	//output wire clk_ref_i,
	output logic selfresetn );

wire centralclocklocked, videoclklocked;//, ddr3clklocked;

centralclockgen centralclock(
	.clk_in1(sys_clock_i),
	.busclock(busclock),
	.wallclock(wallclock),
	.uartbaseclock(uartbaseclock),
	.locked(centralclocklocked) );

/*ddr3clk ddr3memoryclock(
	.clk_in1(sys_clock_i),
	.clk_sys_i(clk_sys_i),
	.clk_ref_i(clk_ref_i),
	.locked(ddr3clklocked) );*/

videoclockgen graphicsclock(
	.clk_in1(sys_clock_i),
	.pixelclock(pixelclock),
	.videoclock(videoclock),
	.locked(videoclklocked) );

// Hold reset until clocks are locked
//wire internalreset = ~(centralclocklocked & videoclklocked & ddr3clklocked);
wire internalreset = ~(centralclocklocked & videoclklocked);

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

endmodule
