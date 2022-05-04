`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/08/2015 06:07:53 PM
// Design Name: 
// Module Name: audio_init
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////



module audio_init(
    input clk,
    input rst,
    inout sda,
    inout scl,
    output initDone );

    parameter stRegAddr1 = 4'b0000;
    parameter stRegAddr2 =   4'b0001;
    parameter stData1 = 4'b0010;
    parameter stData2 = 4'b0011;
    parameter stError =   4'b0100;
    parameter stDone = 4'b0101;
    parameter stIdle = 4'b0110;
    parameter stDelay = 4'b0111;
    parameter stPLLsecond = 4'b1111;
    
    parameter INIT_VECTORS = 35;
    parameter IRD = 1'b1;//init read
    parameter IWR = 1'b0;//init write
    parameter delay = 1000*24;
    
    reg [3:0] state=stIdle;//State machine
    reg [32:0] initWord;
    //reg initFbWe;
    reg initEn;
    reg [6:0]initA=0;

	assign initDone = state == stDone;

    always @(posedge(clk))begin
        case (initA)
             0: initWord <= {IWR,31'h4015_0100}; // Serial port 0 : MS:1
             1: initWord <= {IWR,31'h4016_0000}; // Serial port 1 : -
             2: initWord <= {IWR,31'h4017_0000}; // Converter 0 : CONVSR:000 (48KHz)
             3: initWord <= {IWR,31'h40F8_0000}; // Serial port sampling rate : SPSR:000
             4: initWord <= {IWR,31'h4019_1300}; // ADC control : DMPOL:1 ADCEN:11
             5: initWord <= {IWR,31'h402A_0300}; // DAC control : DACEN:11
             6: initWord <= {IWR,31'h4029_0300}; // Player power mgmt : PREN:1 PLEN:1
             7: initWord <= {IWR,31'h40F2_0100}; // Serial input router ctl : SINRT:001
             8: initWord <= {IWR,31'h40F9_7F00}; // Clock enable 0 : SLEWPD:1 ALCPD:1 DECPD:1 SOUTPD:1 INPTD:1 SINPD:1 SPPD:1
             9: initWord <= {IWR,31'h40FA_0300}; // Clock enable 1 : CLK1:1 CLK0:1

            10: initWord <= {IWR,31'h4020_0300}; // Play L/R mixer left : MX5G3:01 MX5EN:1
            11: initWord <= {IWR,31'h4022_0100}; // Play L/R mixer mono : MX7EN:1
            12: initWord <= {IWR,31'h4021_0900}; // Play L/R mixer right : MX5G4:01 MX6EN:1
            13: initWord <= {IWR,31'h4025_E600}; // Line output left vol : LOUTVOL:111001 (57) LOUTM:1 LOMODE:0
            14: initWord <= {IWR,31'h4026_E600}; // Line output right vol : ROUTVOL:111001 (57) ROUTM:1 ROMODE:0
            15: initWord <= {IWR,31'h4027_0300}; // Play mono output : MONOM:1 MOMODE:1
            16: initWord <= {IWR,31'h4010_0100}; // Record mic bias : MBIEN:1
            17: initWord <= {IWR,31'h4028_0000}; // Pop/click supress : POPMODE:0 POPLESS:0 ASLEW:00 Reserved:0
            18: initWord <= {IWR,31'h4023_E600}; // Play HP left vol LHPVOL:111001 (57) LHPM:1 HPEN:0
            19: initWord <= {IWR,31'h4024_E600}; // Play HP right vol RHPVOL:111001 (57) RHPM:1 HPEN:0

            20: initWord <= {IWR,31'h400A_0100}; // Rec mixer left 0: MX1EN:1
            21: initWord <= {IWR,31'h400B_0500}; // Rec mixer left 1: MX1AUXG:101
            22: initWord <= {IWR,31'h400C_0100}; // Rec mixer right 0: MX2EN:1
            23: initWord <= {IWR,31'h400D_0500}; // Rec mixer right 1: MX2AUXG:101
            24: initWord <= {IWR,31'h400E_0300}; // Left diff input vol: LDMUTE:1 LDEN:1
            25: initWord <= {IWR,31'h400F_0300}; // Right diff input vol: RDMUTE:1 RDEN:1
            26: initWord <= {IWR,31'h401C_2100}; // Play mixer left 0: MX3LM:1 MX3AUXG:0000 MX3EN:1
            27: initWord <= {IWR,31'h401D_0000}; // Play mixer left 1: -
            28: initWord <= {IWR,31'h401E_4100}; // Play mixer right 0: MX4RM:1 MX4LM:0 MX4AUXG:0000 MX4EN:1
            29: initWord <= {IWR,31'h401F_0000}; // Play mixer right 1: -
            30: initWord <= {IWR,31'h40F3_0100}; // Serial output route ctl: SOUTRT:0001
            31: initWord <= {IWR,31'h40F4_0000}; // Serial data/GPIO pin config: LRGP3:0 BGP2:0 SDOGP1:0 SDIGP0:0
            32: initWord <= {IWR,31'h4000_0F00}; // Clock control: CLKSRC:1(PLL clk) INFREQ:11(1024xfs) COREN:1
            33: initWord <= {IWR,31'h4002_007D}; // PLL control: M[15:0]:125
            34: initWord <= {IWR,31'h000C_2101}; // N[15:0]:12 R:0100(int:4) X:00(div:1) Type:1 Lock,PLLEN:0x01
        endcase
    end
    reg msg;//New message signal
    reg stb;//Strobe signal
    reg [7:0] data_i;//Data into TWI controller
    wire [7:0] data_o;//Data out of TWI controller
    wire done;
    wire error;
    wire errortype;
    wire [7:0] twiAddr;//Address of device on TWI
    reg [7:0] regData1;
    
    reg delayEn=0;
    integer delaycnt;
    
    
    assign twiAddr[7:1] = 7'b0111011;

    assign twiAddr[0] = 0;
    
    TWICtl twi_controller(
            .MSG_I(msg),
            .STB_I(stb),
            .A_I(twiAddr),
            .D_I(data_i),
            .D_O(data_o),
            .DONE_O(done),
            .ERR_O(error),
            .CLK(clk),
            .SRST(rst),
            .SDA(sda),
            .SCL(scl)
        );


    
always @(posedge(clk))begin
    if (delayEn==1)
        delaycnt<=delaycnt-1;
    else
        delaycnt<=delay;
end


always @(posedge(clk))begin
    if (rst==1)begin
        state<= stIdle;
        delayEn <= 0;
        initA <=0;
        end
    else begin
        data_i <= "--------";
        stb <= 0;
        msg <= 0;
        
        //initFbWe <= 0;
        case (state) 
            stRegAddr1: begin// Sends x40
                if (done == 1)begin
                    if (error == 1) 
                        state <= stError;
                    else
                        state <= stRegAddr2;
                end
                data_i <= initWord[31:24];
                stb <= 1;
                msg <= 1;
            end
            stRegAddr2: begin    //Sends register address x40(XX)
                if (done == 1)begin
                    if (error == 1)
                        state <= stError;
                    else
                        state <= stData1;
                end
                data_i <= initWord[23:16];
                stb <= 1;
            end
            stData1: begin
                if (done == 1) begin
                    if (error == 1)
                        state <= stError;
                    else begin
                        if (initWord[7:0]!=0)//If there is another byte, send it
                            state <= stData2;
                        else begin//no more bytes to send
                            initEn <= 1;
                            
                            if (initA == INIT_VECTORS-1)//Done with all instructions
                                state <= stDone;
                            else            //Only 3 bytes to send
                                state <= stDelay;
                        end
                    end
                end
                if (initWord[32] == 1) msg <= 1;
                data_i <= initWord[15:8];
                stb <= 1;
            end
            stData2: begin
                if (done == 1)begin
                    if (error == 1)
                        state <= stError;
                    else begin
                        initEn<=1;
                        //if (initWord[32] == 1) initFbWe <= 1;
                        if (initWord[23:16]== 8'h02)begin//If its the PLL register
                            initA<=initA+1;//Move initWord to the remaining PLL config bits
                            state <= stPLLsecond;//And send them
                        end
                        else if (initA == INIT_VECTORS-1)
                            state <= stDone;
                        else
                            state <= stDelay;
                    end
                end
                data_i <= initWord[7:0];
                stb <= 1;
            end
            stPLLsecond:begin
                if (done == 1)begin
                    if (error == 1) 
                        state <= stError;
                    else
                        state <= stRegAddr2;
                end
                data_i <= initWord[31:24];
                stb <= 1;
            end
            stError: begin
                state <= stRegAddr1;
            end
            stDone: begin
            end
            stIdle:begin
                state <= stRegAddr1;
            end
            stDelay:begin
                delayEn <= 1;
                if (delaycnt==0)begin
                    delayEn<=0;
                    if (initEn)begin
                        initA<=initA+1;
                        initEn <= 0;
                    end
                    state<=stRegAddr1;
                end
            end
        endcase
    end
end
endmodule
