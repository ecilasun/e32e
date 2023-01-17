`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Digilent Inc.
// Engineer: Thomas Kappenman
// 
// Create Date: 03/03/2015 09:33:36 PM
// Design Name: 
// Module Name: PS2Receiver
// Project Name: Nexys4DDR Keyboard Demo
// Target Devices: Nexys4DDR
// Tool Versions: 
// Description: PS2 Receiver module used to shift in keycodes from a keyboard plugged into the PS2 port
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module PS2Receiver(
    input clk,
    input kclk,
    input kdata,
    output wire [15:0] keycode,
    output wire oflag );

    wire kclkf, kdataf;
    logic [7:0]datacur=0;
    logic [7:0]dataprev=0;
    logic [3:0]cnt=0;
    logic flag=0;

debouncer #(
    .COUNT_MAX(19),
    .COUNT_WIDTH(5)
) db_clk(
    .clk(clk),
    .I(kclk),
    .O(kclkf)
);
debouncer #(
   .COUNT_MAX(19),
   .COUNT_WIDTH(5)
) db_data(
    .clk(clk),
    .I(kdata),
    .O(kdataf)
);

always@(negedge(kclkf))begin
    case(cnt)
     0:;//Start bit
     1:datacur[0]<=kdataf;
     2:datacur[1]<=kdataf;
     3:datacur[2]<=kdataf;
     4:datacur[3]<=kdataf;
     5:datacur[4]<=kdataf;
     6:datacur[5]<=kdataf;
     7:datacur[6]<=kdataf;
     8:datacur[7]<=kdataf;
     9:flag<=1'b1;
     10:flag<=1'b0;
    endcase

    if(cnt<=9) cnt<=cnt+1;
    else if(cnt==10) cnt<=0;
end

logic pflag = 1'b0;
logic oreg = 1'b0;
logic [15:0] scancode = 16'd0;
always@(posedge clk) begin
    if (flag == 1'b1 && pflag == 1'b0) begin
        scancode <= {dataprev, datacur};
        oreg <= 1'b1;
        dataprev <= datacur;
    end else
        oreg <= 'b0;
    pflag <= flag;
end

assign keycode = scancode;
assign oflag = oreg;

endmodule