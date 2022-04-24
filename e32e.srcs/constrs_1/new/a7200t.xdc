### This file is a general .xdc for the Nexys Video Rev. A
### To use it in a project:
### - uncomment the lines corresponding to used pins
### - rename the used ports (in each line, after get_ports) according to the top level signal names in the project


## Clock Signal
set_property -dict {PACKAGE_PIN R4 IOSTANDARD LVCMOS33} [get_ports sys_clock]
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} -add [get_ports sys_clock]

## FMC Transceiver clocks (Must be set to value provided by Mezzanine card, currently set to 156.25 MHz)
## Note: This clock is attached to a MGTREFCLK pin
#set_property -dict { PACKAGE_PIN E6 } [get_ports { GTP_CLK_N }];
#set_property -dict { PACKAGE_PIN F6 } [get_ports { GTP_CLK_P }];
#create_clock -add -name gtpclk0_pin -period 6.400 -waveform {0 3.200} [get_ports {GTP_CLK_P}];
#set_property -dict { PACKAGE_PIN E10 } [get_ports { FMC_MGT_CLK_N }];
#set_property -dict { PACKAGE_PIN F10 } [get_ports { FMC_MGT_CLK_P }];
#create_clock -add -name mgtclk1_pin -period 6.400 -waveform {0 3.200} [get_ports {FMC_MGT_CLK_P}];


## LEDs
# set_property -dict {PACKAGE_PIN T14 IOSTANDARD LVCMOS25} [get_ports {led[0]}]
# set_property -dict {PACKAGE_PIN T15 IOSTANDARD LVCMOS25} [get_ports {led[1]}]
# set_property -dict {PACKAGE_PIN T16 IOSTANDARD LVCMOS25} [get_ports {led[2]}]
# set_property -dict {PACKAGE_PIN U16 IOSTANDARD LVCMOS25} [get_ports {led[3]}]
# set_property -dict {PACKAGE_PIN V15 IOSTANDARD LVCMOS25} [get_ports {led[4]}]
# set_property -dict {PACKAGE_PIN W16 IOSTANDARD LVCMOS25} [get_ports {led[5]}]
# set_property -dict {PACKAGE_PIN W15 IOSTANDARD LVCMOS25} [get_ports {led[6]}]
# set_property -dict {PACKAGE_PIN Y13 IOSTANDARD LVCMOS25} [get_ports {led[7]}]


## Buttons
# set_property -dict { PACKAGE_PIN B22 IOSTANDARD LVCMOS12 } [get_ports { buttons[0] }]; #IO_L20N_T3_16 Sch=btnc
# set_property -dict { PACKAGE_PIN D22 IOSTANDARD LVCMOS12 } [get_ports { buttons[1] }]; #IO_L22N_T3_16 Sch=btnd
# set_property -dict { PACKAGE_PIN C22 IOSTANDARD LVCMOS12 } [get_ports { buttons[2] }]; #IO_L20P_T3_16 Sch=btnl
# set_property -dict { PACKAGE_PIN D14 IOSTANDARD LVCMOS12 } [get_ports { buttons[3] }]; #IO_L6P_T0_16 Sch=btnr
# set_property -dict { PACKAGE_PIN F15 IOSTANDARD LVCMOS12 } [get_ports { buttons[4] }]; #IO_0_16 Sch=btnu
#set_property -dict { PACKAGE_PIN G4  IOSTANDARD LVCMOS15 } [get_ports { cpu_resetn }]; #IO_L12N_T1_MRCC_35 Sch=cpu_resetn


## Switches
#set_property -dict { PACKAGE_PIN E22  IOSTANDARD LVCMOS12 } [get_ports { sw[0] }]; #IO_L22P_T3_16 Sch=sw[0]
#set_property -dict { PACKAGE_PIN F21  IOSTANDARD LVCMOS12 } [get_ports { sw[1] }]; #IO_25_16 Sch=sw[1]
#set_property -dict { PACKAGE_PIN G21  IOSTANDARD LVCMOS12 } [get_ports { sw[2] }]; #IO_L24P_T3_16 Sch=sw[2]
#set_property -dict { PACKAGE_PIN G22  IOSTANDARD LVCMOS12 } [get_ports { sw[3] }]; #IO_L24N_T3_16 Sch=sw[3]
#set_property -dict { PACKAGE_PIN H17  IOSTANDARD LVCMOS12 } [get_ports { sw[4] }]; #IO_L6P_T0_15 Sch=sw[4]
#set_property -dict { PACKAGE_PIN J16  IOSTANDARD LVCMOS12 } [get_ports { sw[5] }]; #IO_0_15 Sch=sw[5]
#set_property -dict { PACKAGE_PIN K13  IOSTANDARD LVCMOS12 } [get_ports { sw[6] }]; #IO_L19P_T3_A22_15 Sch=sw[6]
#set_property -dict { PACKAGE_PIN M17  IOSTANDARD LVCMOS12 } [get_ports { sw[7] }]; #IO_25_15 Sch=sw[7]


## OLED Display
#set_property -dict { PACKAGE_PIN W22   IOSTANDARD LVCMOS33 } [get_ports { oled_dc }]; #IO_L7N_T1_D10_14 Sch=oled_dc
#set_property -dict { PACKAGE_PIN U21   IOSTANDARD LVCMOS33 } [get_ports { oled_res }]; #IO_L4N_T0_D05_14 Sch=oled_res
#set_property -dict { PACKAGE_PIN W21   IOSTANDARD LVCMOS33 } [get_ports { oled_sclk }]; #IO_L7P_T1_D09_14 Sch=oled_sclk
#set_property -dict { PACKAGE_PIN Y22   IOSTANDARD LVCMOS33 } [get_ports { oled_sdin }]; #IO_L9N_T1_DQS_D13_14 Sch=oled_sdin
#set_property -dict { PACKAGE_PIN P20   IOSTANDARD LVCMOS33 } [get_ports { oled_vbat }]; #IO_0_14 Sch=oled_vbat
#set_property -dict { PACKAGE_PIN V22   IOSTANDARD LVCMOS33 } [get_ports { oled_vdd }]; #IO_L3N_T0_DQS_EMCCLK_14 Sch=oled_vdd


## HDMI in
#set_property -dict { PACKAGE_PIN AA5   IOSTANDARD LVCMOS33 } [get_ports { hdmi_rx_cec }]; #IO_L10P_T1_34 Sch=hdmi_rx_cec
#set_property -dict { PACKAGE_PIN W4    IOSTANDARD TMDS_33  } [get_ports { hdmi_rx_clk_n }]; #IO_L12N_T1_MRCC_34 Sch=hdmi_rx_clk_n
#set_property -dict { PACKAGE_PIN V4    IOSTANDARD TMDS_33  } [get_ports { hdmi_rx_clk_p }]; #IO_L12P_T1_MRCC_34 Sch=hdmi_rx_clk_p
#set_property -dict { PACKAGE_PIN AB12  IOSTANDARD LVCMOS25 } [get_ports { hdmi_rx_hpa }]; #IO_L7N_T1_13 Sch=hdmi_rx_hpa
#set_property -dict { PACKAGE_PIN Y4    IOSTANDARD LVCMOS33 } [get_ports { hdmi_rx_scl }]; #IO_L11P_T1_SRCC_34 Sch=hdmi_rx_scl
#set_property -dict { PACKAGE_PIN AB5   IOSTANDARD LVCMOS33 } [get_ports { hdmi_rx_sda }]; #IO_L10N_T1_34 Sch=hdmi_rx_sda
#set_property -dict { PACKAGE_PIN R3    IOSTANDARD LVCMOS33 } [get_ports { hdmi_rx_txen }]; #IO_L3P_T0_DQS_34 Sch=hdmi_rx_txen
#set_property -dict { PACKAGE_PIN AA3   IOSTANDARD TMDS_33  } [get_ports { hdmi_rx_n[0] }]; #IO_L9N_T1_DQS_34 Sch=hdmi_rx_n[0]
#set_property -dict { PACKAGE_PIN Y3    IOSTANDARD TMDS_33  } [get_ports { hdmi_rx_p[0] }]; #IO_L9P_T1_DQS_34 Sch=hdmi_rx_p[0]
#set_property -dict { PACKAGE_PIN Y2    IOSTANDARD TMDS_33  } [get_ports { hdmi_rx_n[1] }]; #IO_L4N_T0_34 Sch=hdmi_rx_n[1]
#set_property -dict { PACKAGE_PIN W2    IOSTANDARD TMDS_33  } [get_ports { hdmi_rx_p[1] }]; #IO_L4P_T0_34 Sch=hdmi_rx_p[1]
#set_property -dict { PACKAGE_PIN V2    IOSTANDARD TMDS_33  } [get_ports { hdmi_rx_n[2] }]; #IO_L2N_T0_34 Sch=hdmi_rx_n[2]
#set_property -dict { PACKAGE_PIN U2    IOSTANDARD TMDS_33  } [get_ports { hdmi_rx_p[2] }]; #IO_L2P_T0_34 Sch=hdmi_rx_p[2]


## HDMI out : wired as DVI output, only image (no audio)
#set_property -dict { PACKAGE_PIN AA4   IOSTANDARD LVCMOS33 } [get_ports { hdmi_tx_cec }]; #IO_L11N_T1_SRCC_34 Sch=hdmi_tx_cec
#set_property -dict { PACKAGE_PIN AB13  IOSTANDARD LVCMOS25 } [get_ports { hdmi_tx_hpd }]; #IO_L3N_T0_DQS_13 Sch=hdmi_tx_hpd
#set_property -dict { PACKAGE_PIN U3    IOSTANDARD LVCMOS33 } [get_ports { hdmi_tx_rscl }]; #IO_L6P_T0_34 Sch=hdmi_tx_rscl
#set_property -dict { PACKAGE_PIN V3    IOSTANDARD LVCMOS33 } [get_ports { hdmi_tx_rsda }]; #IO_L6N_T0_VREF_34 Sch=hdmi_tx_rsda
set_property -dict {PACKAGE_PIN T1 IOSTANDARD TMDS_33} [get_ports hdmi_tx_clk_p]
set_property -dict {PACKAGE_PIN U1 IOSTANDARD TMDS_33} [get_ports hdmi_tx_clk_n]
set_property -dict {PACKAGE_PIN W1 IOSTANDARD TMDS_33} [get_ports {hdmi_tx_p[0]}]
set_property -dict {PACKAGE_PIN AA1 IOSTANDARD TMDS_33} [get_ports {hdmi_tx_p[1]}]
set_property -dict {PACKAGE_PIN AB3 IOSTANDARD TMDS_33} [get_ports {hdmi_tx_p[2]}]
set_property -dict {PACKAGE_PIN Y1 IOSTANDARD TMDS_33} [get_ports {hdmi_tx_n[0]}]
set_property -dict {PACKAGE_PIN AB1 IOSTANDARD TMDS_33} [get_ports {hdmi_tx_n[1]}]
set_property -dict {PACKAGE_PIN AB2 IOSTANDARD TMDS_33} [get_ports {hdmi_tx_n[2]}]


## Display Port
#set_property -dict { PACKAGE_PIN AB10  IOSTANDARD TMDS_33  } [get_ports { dp_tx_aux_n }]; #IO_L8N_T1_13 Sch=dp_tx_aux_n
#set_property -dict { PACKAGE_PIN AA11  IOSTANDARD TMDS_33  } [get_ports { dp_tx_aux_n }]; #IO_L9N_T1_DQS_13 Sch=dp_tx_aux_n
#set_property -dict { PACKAGE_PIN AA9   IOSTANDARD TMDS_33  } [get_ports { dp_tx_aux_p }]; #IO_L8P_T1_13 Sch=dp_tx_aux_p
#set_property -dict { PACKAGE_PIN AA10  IOSTANDARD TMDS_33  } [get_ports { dp_tx_aux_p }]; #IO_L9P_T1_DQS_13 Sch=dp_tx_aux_p
#set_property -dict { PACKAGE_PIN N15   IOSTANDARD LVCMOS33 } [get_ports { dp_tx_hpd }]; #IO_25_14 Sch=dp_tx_hpd


## Audio Codec
set_property -dict {PACKAGE_PIN T4 IOSTANDARD LVCMOS33} [get_ports ac_adc_sdata]
set_property -dict {PACKAGE_PIN T5 IOSTANDARD LVCMOS33} [get_ports ac_bclk]
set_property -dict {PACKAGE_PIN W6 IOSTANDARD LVCMOS33} [get_ports ac_dac_sdata]
set_property -dict {PACKAGE_PIN U5 IOSTANDARD LVCMOS33} [get_ports ac_lrclk]
set_property -dict {PACKAGE_PIN U6 IOSTANDARD LVCMOS33} [get_ports ac_mclk]


## Pmod header JA
#set_property -dict { PACKAGE_PIN AB22  IOSTANDARD LVCMOS33 } [get_ports { ja[0] }]; #IO_L10N_T1_D15_14 Sch=ja[1]
#set_property -dict { PACKAGE_PIN AB21  IOSTANDARD LVCMOS33 } [get_ports { ja[1] }]; #IO_L10P_T1_D14_14 Sch=ja[2]
#set_property -dict { PACKAGE_PIN AB20  IOSTANDARD LVCMOS33 } [get_ports { ja[2] }]; #IO_L15N_T2_DQS_DOUT_CSO_B_14 Sch=ja[3]
#set_property -dict { PACKAGE_PIN AB18  IOSTANDARD LVCMOS33 } [get_ports { ja[3] }]; #IO_L17N_T2_A13_D29_14 Sch=ja[4]
#set_property -dict { PACKAGE_PIN Y21   IOSTANDARD LVCMOS33 } [get_ports { ja[4] }]; #IO_L9P_T1_DQS_14 Sch=ja[7]
#set_property -dict { PACKAGE_PIN AA21  IOSTANDARD LVCMOS33 } [get_ports { ja[5] }]; #IO_L8N_T1_D12_14 Sch=ja[8]
#set_property -dict { PACKAGE_PIN AA20  IOSTANDARD LVCMOS33 } [get_ports { ja[6] }]; #IO_L8P_T1_D11_14 Sch=ja[9]
#set_property -dict { PACKAGE_PIN AA18  IOSTANDARD LVCMOS33 } [get_ports { ja[7] }]; #IO_L17P_T2_A14_D30_14 Sch=ja[10]


## Pmod header JB
#set_property -dict { PACKAGE_PIN V9    IOSTANDARD LVCMOS33 } [get_ports { jb[0] }]; #IO_L21P_T3_DQS_34 Sch=jb_p[1]
#set_property -dict { PACKAGE_PIN V8    IOSTANDARD LVCMOS33 } [get_ports { jb[1] }]; #IO_L21N_T3_DQS_34 Sch=jb_n[1]
#set_property -dict { PACKAGE_PIN V7    IOSTANDARD LVCMOS33 } [get_ports { jb[2] }]; #IO_L19P_T3_34 Sch=jb_p[2]
#set_property -dict { PACKAGE_PIN W7    IOSTANDARD LVCMOS33 } [get_ports { jb[3] }]; #IO_L19N_T3_VREF_34 Sch=jb_n[2]
#set_property -dict { PACKAGE_PIN W9    IOSTANDARD LVCMOS33 } [get_ports { jb[4] }]; #IO_L24P_T3_34 Sch=jb_p[3]
#set_property -dict { PACKAGE_PIN Y9    IOSTANDARD LVCMOS33 } [get_ports { jb[5] }]; #IO_L24N_T3_34 Sch=jb_n[3]
#set_property -dict { PACKAGE_PIN Y8    IOSTANDARD LVCMOS33 } [get_ports { jb[6] }]; #IO_L23P_T3_34 Sch=jb_p[4]
#set_property -dict { PACKAGE_PIN Y7    IOSTANDARD LVCMOS33 } [get_ports { jb[7] }]; #IO_L23N_T3_34 Sch=jb_n[4]


## Pmod header JC
#set_property -dict { PACKAGE_PIN Y6    IOSTANDARD LVCMOS33 } [get_ports { jc[0] }]; #IO_L18P_T2_34 Sch=jc_p[1]
#set_property -dict { PACKAGE_PIN AA6   IOSTANDARD LVCMOS33 } [get_ports { jc[1] }]; #IO_L18N_T2_34 Sch=jc_n[1]
#set_property -dict { PACKAGE_PIN AA8   IOSTANDARD LVCMOS33 } [get_ports { jc[2] }]; #IO_L22P_T3_34 Sch=jc_p[2]
#set_property -dict { PACKAGE_PIN AB8   IOSTANDARD LVCMOS33 } [get_ports { jc[3] }]; #IO_L22N_T3_34 Sch=jc_n[2]
#set_property -dict { PACKAGE_PIN R6    IOSTANDARD LVCMOS33 } [get_ports { jc[4] }]; #IO_L17P_T2_34 Sch=jc_p[3]
#set_property -dict { PACKAGE_PIN T6    IOSTANDARD LVCMOS33 } [get_ports { jc[5] }]; #IO_L17N_T2_34 Sch=jc_n[3]
#set_property -dict { PACKAGE_PIN AB7   IOSTANDARD LVCMOS33 } [get_ports { jc[6] }]; #IO_L20P_T3_34 Sch=jc_p[4]
#set_property -dict { PACKAGE_PIN AB6   IOSTANDARD LVCMOS33 } [get_ports { jc[7] }]; #IO_L20N_T3_34 Sch=jc_n[4]


## XADC Header
#set_property -dict { PACKAGE_PIN J14   IOSTANDARD LVCMOS33 } [get_ports { xa_p[0] }]; #IO_L3P_T0_DQS_AD1P_15 Sch=xa_p[1]
#set_property -dict { PACKAGE_PIN H14   IOSTANDARD LVCMOS33 } [get_ports { xa_n[0] }]; #IO_L3N_T0_DQS_AD1N_15 Sch=xa_n[1]
#set_property -dict { PACKAGE_PIN H13   IOSTANDARD LVCMOS33 } [get_ports { xa_p[1] }]; #IO_L1P_T0_AD0P_15 Sch=xa_p[2]
#set_property -dict { PACKAGE_PIN G13   IOSTANDARD LVCMOS33 } [get_ports { xa_n[1] }]; #IO_L1N_T0_AD0N_15 Sch=xa_n[2]
#set_property -dict { PACKAGE_PIN G15   IOSTANDARD LVCMOS33 } [get_ports { xa_p[2] }]; #IO_L2P_T0_AD8P_15 Sch=xa_p[3]
#set_property -dict { PACKAGE_PIN G16   IOSTANDARD LVCMOS33 } [get_ports { xa_n[2] }]; #IO_L2N_T0_AD8N_15 Sch=xa_n[3]
#set_property -dict { PACKAGE_PIN J15   IOSTANDARD LVCMOS33 } [get_ports { xa_p[3] }]; #IO_L5P_T0_AD9P_15 Sch=xa_p[4]
#set_property -dict { PACKAGE_PIN H15   IOSTANDARD LVCMOS33 } [get_ports { xa_n[3] }]; #IO_L5N_T0_AD9N_15 Sch=xa_n[4]


## UART
set_property -dict {PACKAGE_PIN AA19 IOSTANDARD LVCMOS33} [get_ports uart_rxd_out]
set_property -dict {PACKAGE_PIN V18 IOSTANDARD LVCMOS33} [get_ports uart_txd_in]


## Ethernet
#set_property -dict { PACKAGE_PIN Y14   IOSTANDARD LVCMOS25 } [get_ports { eth_int_b }]; #IO_L6N_T0_VREF_13 Sch=eth_int_b
#set_property -dict { PACKAGE_PIN AA16  IOSTANDARD LVCMOS25 } [get_ports { eth_mdc }]; #IO_L1N_T0_13 Sch=eth_mdc
#set_property -dict { PACKAGE_PIN Y16   IOSTANDARD LVCMOS25 } [get_ports { eth_mdio }]; #IO_L1P_T0_13 Sch=eth_mdio
#set_property -dict { PACKAGE_PIN W14   IOSTANDARD LVCMOS25 } [get_ports { eth_pme_b }]; #IO_L6P_T0_13 Sch=eth_pme_b
#set_property -dict { PACKAGE_PIN U7    IOSTANDARD LVCMOS33 } [get_ports { eth_rst_b }]; #IO_25_34 Sch=eth_rst_b
#set_property -dict { PACKAGE_PIN V13   IOSTANDARD LVCMOS25 } [get_ports { eth_rxck }]; #IO_L13P_T2_MRCC_13 Sch=eth_rxck
#set_property -dict { PACKAGE_PIN W10   IOSTANDARD LVCMOS25 } [get_ports { eth_rxctl }]; #IO_L10N_T1_13 Sch=eth_rxctl
#set_property -dict { PACKAGE_PIN AB16  IOSTANDARD LVCMOS25 } [get_ports { eth_rxd[0] }]; #IO_L2P_T0_13 Sch=eth_rxd[0]
#set_property -dict { PACKAGE_PIN AA15  IOSTANDARD LVCMOS25 } [get_ports { eth_rxd[1] }]; #IO_L4P_T0_13 Sch=eth_rxd[1]
#set_property -dict { PACKAGE_PIN AB15  IOSTANDARD LVCMOS25 } [get_ports { eth_rxd[2] }]; #IO_L4N_T0_13 Sch=eth_rxd[2]
#set_property -dict { PACKAGE_PIN AB11  IOSTANDARD LVCMOS25 } [get_ports { eth_rxd[3] }]; #IO_L7P_T1_13 Sch=eth_rxd[3]
#set_property -dict { PACKAGE_PIN AA14  IOSTANDARD LVCMOS25 } [get_ports { eth_txck }]; #IO_L5N_T0_13 Sch=eth_txck
#set_property -dict { PACKAGE_PIN V10   IOSTANDARD LVCMOS25 } [get_ports { eth_txctl }]; #IO_L10P_T1_13 Sch=eth_txctl
#set_property -dict { PACKAGE_PIN Y12   IOSTANDARD LVCMOS25 } [get_ports { eth_txd[0] }]; #IO_L11N_T1_SRCC_13 Sch=eth_txd[0]
#set_property -dict { PACKAGE_PIN W12   IOSTANDARD LVCMOS25 } [get_ports { eth_txd[1] }]; #IO_L12N_T1_MRCC_13 Sch=eth_txd[1]
#set_property -dict { PACKAGE_PIN W11   IOSTANDARD LVCMOS25 } [get_ports { eth_txd[2] }]; #IO_L12P_T1_MRCC_13 Sch=eth_txd[2]
#set_property -dict { PACKAGE_PIN Y11   IOSTANDARD LVCMOS25 } [get_ports { eth_txd[3] }]; #IO_L11P_T1_SRCC_13 Sch=eth_txd[3]


## Fan PWM
#set_property -dict { PACKAGE_PIN U15   IOSTANDARD LVCMOS25 } [get_ports { fan_pwm }]; #IO_L14P_T2_SRCC_13 Sch=fan_pwm


## DPTI/DSPI
#set_property -dict { PACKAGE_PIN Y18   IOSTANDARD LVCMOS33 } [get_ports { prog_clko }]; #IO_L13P_T2_MRCC_14 Sch=prog_clko
#set_property -dict { PACKAGE_PIN U20   IOSTANDARD LVCMOS33 } [get_ports { prog_d[0]}]; #IO_L11P_T1_SRCC_14 Sch=prog_d0/sck
#set_property -dict { PACKAGE_PIN P14   IOSTANDARD LVCMOS33 } [get_ports { prog_d[1] }]; #IO_L19P_T3_A10_D26_14 Sch=prog_d1/mosi
#set_property -dict { PACKAGE_PIN P15   IOSTANDARD LVCMOS33 } [get_ports { prog_d[2] }]; #IO_L22P_T3_A05_D21_14 Sch=prog_d2/miso
#set_property -dict { PACKAGE_PIN U17   IOSTANDARD LVCMOS33 } [get_ports { prog_d[3]}]; #IO_L18P_T2_A12_D28_14 Sch=prog_d3/ss
#set_property -dict { PACKAGE_PIN R17   IOSTANDARD LVCMOS33 } [get_ports { prog_d[4] }]; #IO_L24N_T3_A00_D16_14 Sch=prog_d[4]
#set_property -dict { PACKAGE_PIN P16   IOSTANDARD LVCMOS33 } [get_ports { prog_d[5] }]; #IO_L24P_T3_A01_D17_14 Sch=prog_d[5]
#set_property -dict { PACKAGE_PIN R18   IOSTANDARD LVCMOS33 } [get_ports { prog_d[6] }]; #IO_L20P_T3_A08_D24_14 Sch=prog_d[6]
#set_property -dict { PACKAGE_PIN N14   IOSTANDARD LVCMOS33 } [get_ports { prog_d[7] }]; #IO_L23N_T3_A02_D18_14 Sch=prog_d[7]
#set_property -dict { PACKAGE_PIN V17   IOSTANDARD LVCMOS33 } [get_ports { prog_oen }]; #IO_L16P_T2_CSI_B_14 Sch=prog_oen
#set_property -dict { PACKAGE_PIN P19   IOSTANDARD LVCMOS33 } [get_ports { prog_rdn }]; #IO_L5P_T0_D06_14 Sch=prog_rdn
#set_property -dict { PACKAGE_PIN N17   IOSTANDARD LVCMOS33 } [get_ports { prog_rxen }]; #IO_L21P_T3_DQS_14 Sch=prog_rxen
#set_property -dict { PACKAGE_PIN P17   IOSTANDARD LVCMOS33 } [get_ports { prog_siwun }]; #IO_L21N_T3_DQS_A06_D22_14 Sch=prog_siwun
#set_property -dict { PACKAGE_PIN R14   IOSTANDARD LVCMOS33 } [get_ports { prog_spien }]; #IO_L19N_T3_A09_D25_VREF_14 Sch=prog_spien
#set_property -dict { PACKAGE_PIN Y19   IOSTANDARD LVCMOS33 } [get_ports { prog_txen }]; #IO_L13N_T2_MRCC_14 Sch=prog_txen
#set_property -dict { PACKAGE_PIN R19   IOSTANDARD LVCMOS33 } [get_ports { prog_wrn }]; #IO_L5N_T0_D07_14 Sch=prog_wrn


## HID port
set_property PACKAGE_PIN W17 [get_ports ps2_clk]
set_property IOSTANDARD LVCMOS33 [get_ports ps2_clk]
set_property PULLUP true [get_ports ps2_clk]
set_property PACKAGE_PIN N13 [get_ports ps2_data]
set_property IOSTANDARD LVCMOS33 [get_ports ps2_data]
set_property PULLUP true [get_ports ps2_data]


## QSPI
#set_property -dict { PACKAGE_PIN T19   IOSTANDARD LVCMOS33 } [get_ports { qspi_cs }]; #IO_L6P_T0_FCS_B_14 Sch=qspi_cs
#set_property -dict { PACKAGE_PIN P22   IOSTANDARD LVCMOS33 } [get_ports { qspi_dq[0] }]; #IO_L1P_T0_D00_MOSI_14 Sch=qspi_dq[0]
#set_property -dict { PACKAGE_PIN R22   IOSTANDARD LVCMOS33 } [get_ports { qspi_dq[1] }]; #IO_L1N_T0_D01_DIN_14 Sch=qspi_dq[1]
#set_property -dict { PACKAGE_PIN P21   IOSTANDARD LVCMOS33 } [get_ports { qspi_dq[2] }]; #IO_L2P_T0_D02_14 Sch=qspi_dq[2]
#set_property -dict { PACKAGE_PIN R21   IOSTANDARD LVCMOS33 } [get_ports { qspi_dq[3] }]; #IO_L2N_T0_D03_14 Sch=qspi_dq[3]


# SD card : re-wired as SPI style
set_property -dict {PACKAGE_PIN W19 IOSTANDARD LVCMOS33} [get_ports spi_sck]
set_property -dict {PACKAGE_PIN T18 IOSTANDARD LVCMOS33} [get_ports spi_cd]
set_property -dict {PACKAGE_PIN W20 IOSTANDARD LVCMOS33} [get_ports spi_mosi]
set_property -dict {PACKAGE_PIN V19 IOSTANDARD LVCMOS33} [get_ports spi_miso]
set_property -dict {PACKAGE_PIN U18 IOSTANDARD LVCMOS33} [get_ports spi_cs_n]
set_property -dict {PACKAGE_PIN V20 IOSTANDARD LVCMOS33} [get_ports sd_poweron_n]
## SD card : original wiring
#set_property -dict { PACKAGE_PIN W19   IOSTANDARD LVCMOS33 } [get_ports { sd_cclk }]; #IO_L12P_T1_MRCC_14 Sch=sd_cclk >spi_sck
#set_property -dict { PACKAGE_PIN T18   IOSTANDARD LVCMOS33 } [get_ports { sd_cd }]; #IO_L20N_T3_A07_D23_14 Sch=sd_cd <spi_cd
#set_property -dict { PACKAGE_PIN W20   IOSTANDARD LVCMOS33 } [get_ports { sd_cmd }]; #IO_L12N_T1_MRCC_14 Sch=sd_cmd >spi_mosi
#set_property -dict { PACKAGE_PIN V19   IOSTANDARD LVCMOS33 } [get_ports { sd_d[0] }]; #IO_L14N_T2_SRCC_14 Sch=sd_d[0] <spi_miso
#set_property -dict { PACKAGE_PIN T21   IOSTANDARD LVCMOS33 } [get_ports { sd_d[1] }]; #IO_L4P_T0_D04_14 Sch=sd_d[1] n/c
#set_property -dict { PACKAGE_PIN T20   IOSTANDARD LVCMOS33 } [get_ports { sd_d[2] }]; #IO_L6N_T0_D08_VREF_14 Sch=sd_d[2] n/c
#set_property -dict { PACKAGE_PIN U18   IOSTANDARD LVCMOS33 } [get_ports { sd_d[3] }]; #IO_L18N_T2_A11_D27_14 Sch=sd_d[3] >spi_cs_n
#set_property -dict { PACKAGE_PIN V20   IOSTANDARD LVCMOS33 } [get_ports { sd_reset }]; #IO_L11N_T1_SRCC_14 Sch=sd_reset >1'b0


## I2C
set_property -dict {PACKAGE_PIN W5 IOSTANDARD LVCMOS33} [get_ports scl]
set_property -dict {PACKAGE_PIN V5 IOSTANDARD LVCMOS33} [get_ports sda]


## Voltage Adjust
#set_property -dict { PACKAGE_PIN AA13  IOSTANDARD LVCMOS25 } [get_ports { set_vadj[0] }]; #IO_L3P_T0_DQS_13 Sch=set_vadj[0]
#set_property -dict { PACKAGE_PIN AB17  IOSTANDARD LVCMOS25 } [get_ports { set_vadj[1] }]; #IO_L2N_T0_13 Sch=set_vadj[1]
#set_property -dict { PACKAGE_PIN V14   IOSTANDARD LVCMOS25 } [get_ports { vadj_en }]; #IO_L13N_T2_MRCC_13 Sch=vadj_en


##DDR3
# set_property -dict {PACKAGE_PIN M2} [get_ports {ddr3_addr[0]}]
# set_property -dict {PACKAGE_PIN M5} [get_ports {ddr3_addr[1]}]
# set_property -dict {PACKAGE_PIN M3} [get_ports {ddr3_addr[2]}]
# set_property -dict {PACKAGE_PIN M1} [get_ports {ddr3_addr[3]}]
# set_property -dict {PACKAGE_PIN L6} [get_ports {ddr3_addr[4]}]
# set_property -dict {PACKAGE_PIN P1} [get_ports {ddr3_addr[5]}]
# set_property -dict {PACKAGE_PIN N3} [get_ports {ddr3_addr[6]}]
# set_property -dict {PACKAGE_PIN N2} [get_ports {ddr3_addr[7]}]
# set_property -dict {PACKAGE_PIN M6} [get_ports {ddr3_addr[8]}]
# set_property -dict {PACKAGE_PIN R1} [get_ports {ddr3_addr[9]}]
# set_property -dict {PACKAGE_PIN L5} [get_ports {ddr3_addr[10]}]
# set_property -dict {PACKAGE_PIN N5} [get_ports {ddr3_addr[11]}]
# set_property -dict {PACKAGE_PIN N4} [get_ports {ddr3_addr[12]}]
# set_property -dict {PACKAGE_PIN P2} [get_ports {ddr3_addr[13]}]
# set_property -dict {PACKAGE_PIN P6} [get_ports {ddr3_addr[14]}]
# set_property -dict {PACKAGE_PIN L3} [get_ports {ddr3_ba[0]}]
# set_property -dict {PACKAGE_PIN K6} [get_ports {ddr3_ba[1]}]
# set_property -dict {PACKAGE_PIN L4} [get_ports {ddr3_ba[2]}]
# set_property -dict {PACKAGE_PIN K3} [get_ports ddr3_cas_n]
# set_property -dict {PACKAGE_PIN J6} [get_ports ddr3_cke]
# set_property -dict {PACKAGE_PIN P4} [get_ports ddr3_ck_n]
# set_property -dict {PACKAGE_PIN P5} [get_ports ddr3_ck_p]
# set_property -dict {PACKAGE_PIN G3} [get_ports {ddr3_dm[0]}]
# set_property -dict {PACKAGE_PIN F1} [get_ports {ddr3_dm[1]}]
# set_property -dict {PACKAGE_PIN G2} [get_ports {ddr3_dq[0]}]
# set_property -dict {PACKAGE_PIN H4} [get_ports {ddr3_dq[1]}]
# set_property -dict {PACKAGE_PIN H5} [get_ports {ddr3_dq[2]}]
# set_property -dict {PACKAGE_PIN J1} [get_ports {ddr3_dq[3]}]
# set_property -dict {PACKAGE_PIN K1} [get_ports {ddr3_dq[4]}]
# set_property -dict {PACKAGE_PIN H3} [get_ports {ddr3_dq[5]}]
# set_property -dict {PACKAGE_PIN H2} [get_ports {ddr3_dq[6]}]
# set_property -dict {PACKAGE_PIN J5} [get_ports {ddr3_dq[7]}]
# set_property -dict {PACKAGE_PIN E3} [get_ports {ddr3_dq[8]}]
# set_property -dict {PACKAGE_PIN B2} [get_ports {ddr3_dq[9]}]
# set_property -dict {PACKAGE_PIN F3} [get_ports {ddr3_dq[10]}]
# set_property -dict {PACKAGE_PIN D2} [get_ports {ddr3_dq[11]}]
# set_property -dict {PACKAGE_PIN C2} [get_ports {ddr3_dq[12]}]
# set_property -dict {PACKAGE_PIN A1} [get_ports {ddr3_dq[13]}]
# set_property -dict {PACKAGE_PIN E2} [get_ports {ddr3_dq[14]}]
# set_property -dict {PACKAGE_PIN B1} [get_ports {ddr3_dq[15]}]
# set_property -dict {PACKAGE_PIN J2} [get_ports {ddr3_dqs_n[0]}]
# set_property -dict {PACKAGE_PIN K2} [get_ports {ddr3_dqs_p[0]}]
# set_property -dict {PACKAGE_PIN D1} [get_ports {ddr3_dqs_n[1]}]
# set_property -dict {PACKAGE_PIN E1} [get_ports {ddr3_dqs_p[1]}]
# set_property -dict {PACKAGE_PIN K4} [get_ports ddr3_odt]
# set_property -dict {PACKAGE_PIN J4} [get_ports ddr3_ras_n]
# set_property -dict {PACKAGE_PIN G1} [get_ports { ddr3_reset_n }]; #IO_L5P_T0_AD13P_35 Sch=ddr3_reset
# set_property -dict {PACKAGE_PIN L1} [get_ports ddr3_we_n]


## FMC
#set_property -dict { PACKAGE_PIN H19   IOSTANDARD LVCMOS12 } [get_ports { fmc_clk0_m2c_n }]; #IO_L12N_T1_MRCC_15 Sch=fmc_clk0_m2c_n
#set_property -dict { PACKAGE_PIN J19   IOSTANDARD LVCMOS12 } [get_ports { fmc_clk0_m2c_p }]; #IO_L12P_T1_MRCC_15 Sch=fmc_clk0_m2c_p
#set_property -dict { PACKAGE_PIN C19   IOSTANDARD LVCMOS12 } [get_ports { fmc_clk1_m2c_n }]; #IO_L13N_T2_MRCC_16 Sch=fmc_clk1_m2c_n
#set_property -dict { PACKAGE_PIN C18   IOSTANDARD LVCMOS12 } [get_ports { fmc_clk1_m2c_p }]; #IO_L13P_T2_MRCC_16 Sch=fmc_clk1_m2c_p
#set_property -dict { PACKAGE_PIN K19   IOSTANDARD LVCMOS12 } [get_ports { fmc_la00_cc_n }]; #IO_L13N_T2_MRCC_15 Sch=fmc_la00_cc_n
#set_property -dict { PACKAGE_PIN K18   IOSTANDARD LVCMOS12 } [get_ports { fmc_la00_cc_p }]; #IO_L13P_T2_MRCC_15 Sch=fmc_la00_cc_p
#set_property -dict { PACKAGE_PIN J21   IOSTANDARD LVCMOS12 } [get_ports { fmc_la01_cc_n }]; #IO_L11N_T1_SRCC_15 Sch=fmc_la01_cc_n
#set_property -dict { PACKAGE_PIN J20   IOSTANDARD LVCMOS12 } [get_ports { fmc_la01_cc_p }]; #IO_L11P_T1_SRCC_15 Sch=fmc_la01_cc_p
#set_property -dict { PACKAGE_PIN L18   IOSTANDARD LVCMOS12 } [get_ports { fmc_la_n[02] }]; #IO_L16N_T2_A27_15 Sch=fmc_la_n[02]
#set_property -dict { PACKAGE_PIN M18   IOSTANDARD LVCMOS12 } [get_ports { fmc_la_p[02] }]; #IO_L16P_T2_A28_15 Sch=fmc_la_p[02]
#set_property -dict { PACKAGE_PIN N19   IOSTANDARD LVCMOS12 } [get_ports { fmc_la_n[03] }]; #IO_L17N_T2_A25_15 Sch=fmc_la_n[03]
#set_property -dict { PACKAGE_PIN N18   IOSTANDARD LVCMOS12 } [get_ports { fmc_la_p[03] }]; #IO_L17P_T2_A26_15 Sch=fmc_la_p[03]
#set_property -dict { PACKAGE_PIN M20   IOSTANDARD LVCMOS12 } [get_ports { fmc_la_n[04] }]; #IO_L18N_T2_A23_15 Sch=fmc_la_n[04]
#set_property -dict { PACKAGE_PIN N20   IOSTANDARD LVCMOS12 } [get_ports { fmc_la_p[04] }]; #IO_L18P_T2_A24_15 Sch=fmc_la_p[04]
#set_property -dict { PACKAGE_PIN L21   IOSTANDARD LVCMOS12 } [get_ports { fmc_la_n[05] }]; #IO_L10N_T1_AD11N_15 Sch=fmc_la_n[05]
#set_property -dict { PACKAGE_PIN M21   IOSTANDARD LVCMOS12 } [get_ports { fmc_la_p[05] }]; #IO_L10P_T1_AD11P_15 Sch=fmc_la_p[05]
#set_property -dict { PACKAGE_PIN M22   IOSTANDARD LVCMOS12 } [get_ports { fmc_la_n[06] }]; #IO_L15N_T2_DQS_ADV_B_15 Sch=fmc_la_n[06]
#set_property -dict { PACKAGE_PIN N22   IOSTANDARD LVCMOS12 } [get_ports { fmc_la_p[06] }]; #IO_L15P_T2_DQS_15 Sch=fmc_la_p[06]
#set_property -dict { PACKAGE_PIN L13   IOSTANDARD LVCMOS12 } [get_ports { fmc_la_n[07] }]; #IO_L20N_T3_A19_15 Sch=fmc_la_n[07]
#set_property -dict { PACKAGE_PIN M13   IOSTANDARD LVCMOS12 } [get_ports { fmc_la_p[07] }]; #IO_L20P_T3_A20_15 Sch=fmc_la_p[07]
#set_property -dict { PACKAGE_PIN M16   IOSTANDARD LVCMOS12 } [get_ports { fmc_la_n[08] }]; #IO_L24N_T3_RS0_15 Sch=fmc_la_n[08]
#set_property -dict { PACKAGE_PIN M15   IOSTANDARD LVCMOS12 } [get_ports { fmc_la_p[08] }]; #IO_L24P_T3_RS1_15 Sch=fmc_la_p[08]
#set_property -dict { PACKAGE_PIN G20   IOSTANDARD LVCMOS12 } [get_ports { fmc_la_n[09] }]; #IO_L8N_T1_AD10N_15 Sch=fmc_la_n[09]
#set_property -dict { PACKAGE_PIN H20   IOSTANDARD LVCMOS12 } [get_ports { fmc_la_p[09] }]; #IO_L8P_T1_AD10P_15 Sch=fmc_la_p[09]
#set_property -dict { PACKAGE_PIN K22   IOSTANDARD LVCMOS12 } [get_ports { fmc_la_n[10] }]; #IO_L9N_T1_DQS_AD3N_15 Sch=fmc_la_n[10]
#set_property -dict { PACKAGE_PIN K21   IOSTANDARD LVCMOS12 } [get_ports { fmc_la_p[10] }]; #IO_L9P_T1_DQS_AD3P_15 Sch=fmc_la_p[10]
#set_property -dict { PACKAGE_PIN L15   IOSTANDARD LVCMOS12 } [get_ports { fmc_la_n[11] }]; #IO_L22N_T3_A16_15 Sch=fmc_la_n[11]
#set_property -dict { PACKAGE_PIN L14   IOSTANDARD LVCMOS12 } [get_ports { fmc_la_p[11] }]; #IO_L22P_T3_A17_15 Sch=fmc_la_p[11]
#set_property -dict { PACKAGE_PIN L20   IOSTANDARD LVCMOS12 } [get_ports { fmc_la_n[12] }]; #IO_L14N_T2_SRCC_15 Sch=fmc_la_n[12]
#set_property -dict { PACKAGE_PIN L19   IOSTANDARD LVCMOS12 } [get_ports { fmc_la_p[12] }]; #IO_L14P_T2_SRCC_15 Sch=fmc_la_p[12]
#set_property -dict { PACKAGE_PIN J17   IOSTANDARD LVCMOS12 } [get_ports { fmc_la_n[13] }]; #IO_L21N_T3_DQS_A18_15 Sch=fmc_la_n[13]
#set_property -dict { PACKAGE_PIN K17   IOSTANDARD LVCMOS12 } [get_ports { fmc_la_p[13] }]; #IO_L21P_T3_DQS_15 Sch=fmc_la_p[13]
#set_property -dict { PACKAGE_PIN H22   IOSTANDARD LVCMOS12 } [get_ports { fmc_la_n[14] }]; #IO_L7N_T1_AD2N_15 Sch=fmc_la_n[14]
#set_property -dict { PACKAGE_PIN J22   IOSTANDARD LVCMOS12 } [get_ports { fmc_la_p[14] }]; #IO_L7P_T1_AD2P_15 Sch=fmc_la_p[14]
#set_property -dict { PACKAGE_PIN K16   IOSTANDARD LVCMOS12 } [get_ports { fmc_la_n[15] }]; #IO_L23N_T3_FWE_B_15 Sch=fmc_la_n[15]
#set_property -dict { PACKAGE_PIN L16   IOSTANDARD LVCMOS12 } [get_ports { fmc_la_p[15] }]; #IO_L23P_T3_FOE_B_15 Sch=fmc_la_p[15]
#set_property -dict { PACKAGE_PIN G18   IOSTANDARD LVCMOS12 } [get_ports { fmc_la_n[16] }]; #IO_L4N_T0_15 Sch=fmc_la_n[16]
#set_property -dict { PACKAGE_PIN G17   IOSTANDARD LVCMOS12 } [get_ports { fmc_la_p[16] }]; #IO_L4P_T0_15 Sch=fmc_la_p[16]
#set_property -dict { PACKAGE_PIN B18   IOSTANDARD LVCMOS12 } [get_ports { fmc_la17_cc_n }]; #IO_L11N_T1_SRCC_16 Sch=fmc_la17_cc_n
#set_property -dict { PACKAGE_PIN B17   IOSTANDARD LVCMOS12 } [get_ports { fmc_la17_cc_p }]; #IO_L11P_T1_SRCC_16 Sch=fmc_la17_cc_p
#set_property -dict { PACKAGE_PIN C17   IOSTANDARD LVCMOS12 } [get_ports { fmc_la18_cc_n }]; #IO_L12N_T1_MRCC_16 Sch=fmc_la18_cc_n
#set_property -dict { PACKAGE_PIN D17   IOSTANDARD LVCMOS12 } [get_ports { fmc_la18_cc_p }]; #IO_L12P_T1_MRCC_16 Sch=fmc_la18_cc_p
#set_property -dict { PACKAGE_PIN A19   IOSTANDARD LVCMOS12 } [get_ports { fmc_la_n[19] }]; #IO_L17N_T2_16 Sch=fmc_la_n[19]
#set_property -dict { PACKAGE_PIN A18   IOSTANDARD LVCMOS12 } [get_ports { fmc_la_p[19] }]; #IO_L17P_T2_16 Sch=fmc_la_p[19]
#set_property -dict { PACKAGE_PIN F20   IOSTANDARD LVCMOS12 } [get_ports { fmc_la_n[20] }]; #IO_L18N_T2_16 Sch=fmc_la_n[20]
#set_property -dict { PACKAGE_PIN F19   IOSTANDARD LVCMOS12 } [get_ports { fmc_la_p[20] }]; #IO_L18P_T2_16 Sch=fmc_la_p[20]
#set_property -dict { PACKAGE_PIN D19   IOSTANDARD LVCMOS12 } [get_ports { fmc_la_n[21] }]; #IO_L14N_T2_SRCC_16 Sch=fmc_la_n[21]
#set_property -dict { PACKAGE_PIN E19   IOSTANDARD LVCMOS12 } [get_ports { fmc_la_p[21] }]; #IO_L14P_T2_SRCC_16 Sch=fmc_la_p[21]
#set_property -dict { PACKAGE_PIN D21   IOSTANDARD LVCMOS12 } [get_ports { fmc_la_n[22] }]; #IO_L23N_T3_16 Sch=fmc_la_n[22]
#set_property -dict { PACKAGE_PIN E21   IOSTANDARD LVCMOS12 } [get_ports { fmc_la_p[22] }]; #IO_L23P_T3_16 Sch=fmc_la_p[22]
#set_property -dict { PACKAGE_PIN A21   IOSTANDARD LVCMOS12 } [get_ports { fmc_la_n[23] }]; #IO_L21N_T3_DQS_16 Sch=fmc_la_n[23]
#set_property -dict { PACKAGE_PIN B21   IOSTANDARD LVCMOS12 } [get_ports { fmc_la_p[23] }]; #IO_L21P_T3_DQS_16 Sch=fmc_la_p[23]
#set_property -dict { PACKAGE_PIN B16   IOSTANDARD LVCMOS12 } [get_ports { fmc_la_n[24] }]; #IO_L7N_T1_16 Sch=fmc_la_n[24]
#set_property -dict { PACKAGE_PIN B15   IOSTANDARD LVCMOS12 } [get_ports { fmc_la_p[24] }]; #IO_L7P_T1_16 Sch=fmc_la_p[24]
#set_property -dict { PACKAGE_PIN E17   IOSTANDARD LVCMOS12 } [get_ports { fmc_la_n[25] }]; #IO_L2N_T0_16 Sch=fmc_la_n[25]
#set_property -dict { PACKAGE_PIN F16   IOSTANDARD LVCMOS12 } [get_ports { fmc_la_p[25] }]; #IO_L2P_T0_16 Sch=fmc_la_p[25]
#set_property -dict { PACKAGE_PIN E18   IOSTANDARD LVCMOS12 } [get_ports { fmc_la_n[26] }]; #IO_L15N_T2_DQS_16 Sch=fmc_la_n[26]
#set_property -dict { PACKAGE_PIN F18   IOSTANDARD LVCMOS12 } [get_ports { fmc_la_p[26] }]; #IO_L15P_T2_DQS_16 Sch=fmc_la_p[26]
#set_property -dict { PACKAGE_PIN A20   IOSTANDARD LVCMOS12 } [get_ports { fmc_la_n[27] }]; #IO_L16N_T2_16 Sch=fmc_la_n[27]
#set_property -dict { PACKAGE_PIN B20   IOSTANDARD LVCMOS12 } [get_ports { fmc_la_p[27] }]; #IO_L16P_T2_16 Sch=fmc_la_p[27]
#set_property -dict { PACKAGE_PIN B13   IOSTANDARD LVCMOS12 } [get_ports { fmc_la_n[28] }]; #IO_L8N_T1_16 Sch=fmc_la_n[28]
#set_property -dict { PACKAGE_PIN C13   IOSTANDARD LVCMOS12 } [get_ports { fmc_la_p[28] }]; #IO_L8P_T1_16 Sch=fmc_la_p[28]
#set_property -dict { PACKAGE_PIN C15   IOSTANDARD LVCMOS12 } [get_ports { fmc_la_n[29] }]; #IO_L3N_T0_DQS_16 Sch=fmc_la_n[29]
#set_property -dict { PACKAGE_PIN C14   IOSTANDARD LVCMOS12 } [get_ports { fmc_la_p[29] }]; #IO_L3P_T0_DQS_16 Sch=fmc_la_p[29]
#set_property -dict { PACKAGE_PIN A14   IOSTANDARD LVCMOS12 } [get_ports { fmc_la_n[30] }]; #IO_L10N_T1_16 Sch=fmc_la_n[30]
#set_property -dict { PACKAGE_PIN A13   IOSTANDARD LVCMOS12 } [get_ports { fmc_la_p[30] }]; #IO_L10P_T1_16 Sch=fmc_la_p[30]
#set_property -dict { PACKAGE_PIN E14   IOSTANDARD LVCMOS12 } [get_ports { fmc_la_n[31] }]; #IO_L4N_T0_16 Sch=fmc_la_n[31]
#set_property -dict { PACKAGE_PIN E13   IOSTANDARD LVCMOS12 } [get_ports { fmc_la_p[31] }]; #IO_L4P_T0_16 Sch=fmc_la_p[31]
#set_property -dict { PACKAGE_PIN A16   IOSTANDARD LVCMOS12 } [get_ports { fmc_la_n[32] }]; #IO_L9N_T1_DQS_16 Sch=fmc_la_n[32]
#set_property -dict { PACKAGE_PIN A15   IOSTANDARD LVCMOS12 } [get_ports { fmc_la_p[32] }]; #IO_L9P_T1_DQS_16 Sch=fmc_la_p[32]
#set_property -dict { PACKAGE_PIN F14   IOSTANDARD LVCMOS12 } [get_ports { fmc_la_n[33] }]; #IO_L1N_T0_16 Sch=fmc_la_n[33]
#set_property -dict { PACKAGE_PIN F13   IOSTANDARD LVCMOS12 } [get_ports { fmc_la_p[33] }]; #IO_L1P_T0_16 Sch=fmc_la_p[33]


## Configuration options, can be used for all designs
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]

# Reset is a false path
set_false_path -from [get_pins ClockAndResetGen/selfresetn_reg/C]
# set_false_path -to [get_pins ClockAndResetGen/calib_done]
# CSR register mapped times are not that critical and are false paths
set_false_path -from [get_pins {wallclocktime_reg[*]/C}]
set_false_path -from [get_pins {cpuclocktime_reg[*]/C}]
# MISC
# set_false_path -to [get_ports led[*]]
# set_false_path -to [get_ports uart_txd_in]
# set_false_path -to [get_ports uart_rxd_out]







create_pblock pblock_HART0
add_cells_to_pblock [get_pblocks pblock_HART0] [get_cells -quiet {HART0/ALU HART0/BLU HART0/CACHE HART0/CSRREGS HART0/DECODER HART0/FREGS HART0/GND HART0/IDIVS HART0/IDIVU HART0/IMULSU {HART0/PC[31]_i_1} {HART0/PC_reg[0]} {HART0/PC_reg[10]} {HART0/PC_reg[11]} {HART0/PC_reg[12]} {HART0/PC_reg[13]} {HART0/PC_reg[14]} {HART0/PC_reg[15]} {HART0/PC_reg[16]} {HART0/PC_reg[17]} {HART0/PC_reg[18]} {HART0/PC_reg[19]} {HART0/PC_reg[1]} {HART0/PC_reg[20]} {HART0/PC_reg[21]} {HART0/PC_reg[22]} {HART0/PC_reg[23]} {HART0/PC_reg[24]} {HART0/PC_reg[25]} {HART0/PC_reg[26]} {HART0/PC_reg[27]} {HART0/PC_reg[28]} {HART0/PC_reg[29]} {HART0/PC_reg[2]} {HART0/PC_reg[30]} {HART0/PC_reg[31]} {HART0/PC_reg[3]} {HART0/PC_reg[4]} {HART0/PC_reg[5]} {HART0/PC_reg[6]} {HART0/PC_reg[7]} {HART0/PC_reg[8]} {HART0/PC_reg[9]} HART0/REGS HART0/VCC {HART0/addr_reg[0]} {HART0/addr_reg[10]} {HART0/addr_reg[11]} {HART0/addr_reg[12]} {HART0/addr_reg[13]} {HART0/addr_reg[14]} {HART0/addr_reg[15]} {HART0/addr_reg[16]} {HART0/addr_reg[17]} {HART0/addr_reg[18]} {HART0/addr_reg[19]} {HART0/addr_reg[1]} {HART0/addr_reg[20]} {HART0/addr_reg[21]} {HART0/addr_reg[22]} {HART0/addr_reg[23]} {HART0/addr_reg[24]} {HART0/addr_reg[25]} {HART0/addr_reg[26]} {HART0/addr_reg[27]} {HART0/addr_reg[28]} {HART0/addr_reg[29]} {HART0/addr_reg[2]} {HART0/addr_reg[30]} {HART0/addr_reg[31]} {HART0/addr_reg[3]} {HART0/addr_reg[4]} {HART0/addr_reg[5]} {HART0/addr_reg[6]} {HART0/addr_reg[7]} {HART0/addr_reg[8]} {HART0/addr_reg[9]} {HART0/adjacentPC[4]_i_2} {HART0/adjacentPC_reg[0]} {HART0/adjacentPC_reg[10]} {HART0/adjacentPC_reg[11]} {HART0/adjacentPC_reg[12]} {HART0/adjacentPC_reg[12]_i_1} {HART0/adjacentPC_reg[13]} {HART0/adjacentPC_reg[14]} {HART0/adjacentPC_reg[15]} {HART0/adjacentPC_reg[16]} {HART0/adjacentPC_reg[16]_i_1} {HART0/adjacentPC_reg[17]} {HART0/adjacentPC_reg[18]} {HART0/adjacentPC_reg[19]} {HART0/adjacentPC_reg[1]} {HART0/adjacentPC_reg[20]} {HART0/adjacentPC_reg[20]_i_1} {HART0/adjacentPC_reg[21]} {HART0/adjacentPC_reg[22]} {HART0/adjacentPC_reg[23]} {HART0/adjacentPC_reg[24]} {HART0/adjacentPC_reg[24]_i_1} {HART0/adjacentPC_reg[25]} {HART0/adjacentPC_reg[26]} {HART0/adjacentPC_reg[27]} {HART0/adjacentPC_reg[28]} {HART0/adjacentPC_reg[28]_i_1} {HART0/adjacentPC_reg[29]} {HART0/adjacentPC_reg[2]} {HART0/adjacentPC_reg[30]} {HART0/adjacentPC_reg[31]} {HART0/adjacentPC_reg[31]_i_1} {HART0/adjacentPC_reg[3]} {HART0/adjacentPC_reg[4]} {HART0/adjacentPC_reg[4]_i_1} {HART0/adjacentPC_reg[5]} {HART0/adjacentPC_reg[6]} {HART0/adjacentPC_reg[7]} {HART0/adjacentPC_reg[8]} {HART0/adjacentPC_reg[8]_i_1} {HART0/adjacentPC_reg[9]} {HART0/cpustate[1]_i_5} {HART0/cpustate[2]_i_3} {HART0/cpustate[3]_i_1} {HART0/cpustate[3]_i_10} {HART0/cpustate[3]_i_9} {HART0/cpustate_reg[0]} {HART0/cpustate_reg[1]} {HART0/cpustate_reg[2]} {HART0/cpustate_reg[3]} {HART0/csrdin[0]_i_2} {HART0/csrdin[0]_i_6} {HART0/csrdin[10]_i_4} {HART0/csrdin[11]_i_5} {HART0/csrdin[12]_i_5} {HART0/csrdin[13]_i_5} {HART0/csrdin[14]_i_5} {HART0/csrdin[15]_i_5} {HART0/csrdin[16]_i_5} {HART0/csrdin[17]_i_5} {HART0/csrdin[18]_i_5} {HART0/csrdin[19]_i_5} {HART0/csrdin[1]_i_5} {HART0/csrdin[20]_i_5} {HART0/csrdin[21]_i_5} {HART0/csrdin[22]_i_5} {HART0/csrdin[23]_i_5} {HART0/csrdin[24]_i_5} {HART0/csrdin[25]_i_5} {HART0/csrdin[26]_i_5} {HART0/csrdin[27]_i_5} {HART0/csrdin[28]_i_5} {HART0/csrdin[29]_i_5} {HART0/csrdin[2]_i_4} {HART0/csrdin[30]_i_5} {HART0/csrdin[31]_i_12} {HART0/csrdin[31]_i_18} {HART0/csrdin[31]_i_5} {HART0/csrdin[3]_i_4} {HART0/csrdin[3]_i_5} {HART0/csrdin[3]_i_6} {HART0/csrdin[3]_i_7} {HART0/csrdin[4]_i_4} {HART0/csrdin[5]_i_4} {HART0/csrdin[6]_i_4} {HART0/csrdin[7]_i_3} {HART0/csrdin[8]_i_4} {HART0/csrdin[9]_i_4} {HART0/csrdin_reg[0]} {HART0/csrdin_reg[10]} {HART0/csrdin_reg[11]} {HART0/csrdin_reg[12]} {HART0/csrdin_reg[13]} {HART0/csrdin_reg[14]} {HART0/csrdin_reg[15]} {HART0/csrdin_reg[16]} {HART0/csrdin_reg[17]} {HART0/csrdin_reg[18]} {HART0/csrdin_reg[19]} {HART0/csrdin_reg[1]} {HART0/csrdin_reg[20]} {HART0/csrdin_reg[21]} {HART0/csrdin_reg[22]} {HART0/csrdin_reg[23]} {HART0/csrdin_reg[24]} {HART0/csrdin_reg[25]} {HART0/csrdin_reg[26]} {HART0/csrdin_reg[27]} {HART0/csrdin_reg[28]} {HART0/csrdin_reg[29]} {HART0/csrdin_reg[2]} {HART0/csrdin_reg[30]} {HART0/csrdin_reg[31]} {HART0/csrdin_reg[3]} {HART0/csrdin_reg[4]} {HART0/csrdin_reg[5]} {HART0/csrdin_reg[6]} {HART0/csrdin_reg[7]} {HART0/csrdin_reg[8]} {HART0/csrdin_reg[9]} {HART0/csrenforceindex[2]_i_3} {HART0/csrenforceindex_reg[0]} {HART0/csrenforceindex_reg[1]} {HART0/csrenforceindex_reg[2]} {HART0/csrprevval[31]_i_1} {HART0/csrprevval_reg[0]} {HART0/csrprevval_reg[10]} {HART0/csrprevval_reg[11]} {HART0/csrprevval_reg[12]} {HART0/csrprevval_reg[13]} {HART0/csrprevval_reg[14]} {HART0/csrprevval_reg[15]} {HART0/csrprevval_reg[16]} {HART0/csrprevval_reg[17]} {HART0/csrprevval_reg[18]} {HART0/csrprevval_reg[19]} {HART0/csrprevval_reg[1]} {HART0/csrprevval_reg[20]} {HART0/csrprevval_reg[21]} {HART0/csrprevval_reg[22]} {HART0/csrprevval_reg[23]} {HART0/csrprevval_reg[24]} {HART0/csrprevval_reg[25]} {HART0/csrprevval_reg[26]} {HART0/csrprevval_reg[27]} {HART0/csrprevval_reg[28]} {HART0/csrprevval_reg[29]} {HART0/csrprevval_reg[2]} {HART0/csrprevval_reg[30]} {HART0/csrprevval_reg[31]} {HART0/csrprevval_reg[3]} {HART0/csrprevval_reg[4]} {HART0/csrprevval_reg[5]} {HART0/csrprevval_reg[6]} {HART0/csrprevval_reg[7]} {HART0/csrprevval_reg[8]} {HART0/csrprevval_reg[9]} HART0/csrwe_reg HART0/csrwenforce_reg {HART0/dcacheop[0]_i_1} {HART0/dcacheop[2]_i_3} {HART0/dcacheop_reg[0]} {HART0/dcacheop_reg[1]} {HART0/dcacheop_reg[2]} {HART0/dout_reg[0]} {HART0/dout_reg[10]} {HART0/dout_reg[11]} {HART0/dout_reg[12]} {HART0/dout_reg[13]} {HART0/dout_reg[14]} {HART0/dout_reg[15]} {HART0/dout_reg[16]} {HART0/dout_reg[17]} {HART0/dout_reg[18]} {HART0/dout_reg[19]} {HART0/dout_reg[1]} {HART0/dout_reg[20]} {HART0/dout_reg[21]} {HART0/dout_reg[22]} {HART0/dout_reg[23]} {HART0/dout_reg[24]} {HART0/dout_reg[25]} {HART0/dout_reg[26]} {HART0/dout_reg[27]} {HART0/dout_reg[28]} {HART0/dout_reg[29]} {HART0/dout_reg[2]} {HART0/dout_reg[30]} {HART0/dout_reg[31]} {HART0/dout_reg[3]} {HART0/dout_reg[4]} {HART0/dout_reg[5]} {HART0/dout_reg[6]} {HART0/dout_reg[7]} {HART0/dout_reg[8]} {HART0/dout_reg[9]} HART0/ebreak_reg HART0/ecall_reg HART0/faddstrobe_reg HART0/fdivstrobe_reg HART0/feqstrobe_reg HART0/ff2istrobe_reg HART0/ff2uistrobe_reg HART0/fi2fstrobe_reg HART0/flestrobe_reg HART0/fltstrobe_reg HART0/fmaddstrobe_reg HART0/fmsubstrobe_reg HART0/fmulstrobe_reg HART0/fnmaddstrobe_reg HART0/fnmsubstrobe_reg {HART0/frdin[0]_i_6} {HART0/frdin[31]_i_11} {HART0/frdin[31]_i_5} {HART0/frdin_reg[0]} {HART0/frdin_reg[10]} {HART0/frdin_reg[11]} {HART0/frdin_reg[12]} {HART0/frdin_reg[13]} {HART0/frdin_reg[14]} {HART0/frdin_reg[15]} {HART0/frdin_reg[16]} {HART0/frdin_reg[17]} {HART0/frdin_reg[18]} {HART0/frdin_reg[19]} {HART0/frdin_reg[1]} {HART0/frdin_reg[20]} {HART0/frdin_reg[21]} {HART0/frdin_reg[22]} {HART0/frdin_reg[23]} {HART0/frdin_reg[24]} {HART0/frdin_reg[25]} {HART0/frdin_reg[26]} {HART0/frdin_reg[27]} {HART0/frdin_reg[28]} {HART0/frdin_reg[29]} {HART0/frdin_reg[2]} {HART0/frdin_reg[30]} {HART0/frdin_reg[31]} {HART0/frdin_reg[3]} {HART0/frdin_reg[4]} {HART0/frdin_reg[5]} {HART0/frdin_reg[6]} {HART0/frdin_reg[7]} {HART0/frdin_reg[8]} {HART0/frdin_reg[9]} HART0/frwe_reg HART0/fsqrtstrobe_reg HART0/fsubstrobe_reg HART0/fui2fstrobe_reg HART0/ifetch_reg HART0/illegalinstruction_i_3 HART0/illegalinstruction_reg {HART0/nextPC[31]_i_1} {HART0/nextPC_reg[0]} {HART0/nextPC_reg[10]} {HART0/nextPC_reg[11]} {HART0/nextPC_reg[12]} {HART0/nextPC_reg[13]} {HART0/nextPC_reg[14]} {HART0/nextPC_reg[15]} {HART0/nextPC_reg[16]} {HART0/nextPC_reg[17]} {HART0/nextPC_reg[18]} {HART0/nextPC_reg[19]} {HART0/nextPC_reg[1]} {HART0/nextPC_reg[20]} {HART0/nextPC_reg[21]} {HART0/nextPC_reg[22]} {HART0/nextPC_reg[23]} {HART0/nextPC_reg[24]} {HART0/nextPC_reg[25]} {HART0/nextPC_reg[26]} {HART0/nextPC_reg[27]} {HART0/nextPC_reg[28]} {HART0/nextPC_reg[29]} {HART0/nextPC_reg[2]} {HART0/nextPC_reg[30]} {HART0/nextPC_reg[31]} {HART0/nextPC_reg[3]} {HART0/nextPC_reg[4]} {HART0/nextPC_reg[5]} {HART0/nextPC_reg[6]} {HART0/nextPC_reg[7]} {HART0/nextPC_reg[8]} {HART0/nextPC_reg[9]} {HART0/rdin[30]_i_3} {HART0/rdin[31]_i_14} {HART0/rdin[31]_i_28} {HART0/rdin[31]_i_62} {HART0/rdin[31]_i_63} {HART0/rdin[31]_i_64} {HART0/rdin[31]_i_80} {HART0/rdin[7]_i_6} {HART0/rdin_reg[0]} {HART0/rdin_reg[10]} {HART0/rdin_reg[11]} {HART0/rdin_reg[12]} {HART0/rdin_reg[13]} {HART0/rdin_reg[14]} {HART0/rdin_reg[15]} {HART0/rdin_reg[16]} {HART0/rdin_reg[17]} {HART0/rdin_reg[18]} {HART0/rdin_reg[19]} {HART0/rdin_reg[1]} {HART0/rdin_reg[20]} {HART0/rdin_reg[21]} {HART0/rdin_reg[22]} {HART0/rdin_reg[23]} {HART0/rdin_reg[24]} {HART0/rdin_reg[25]} {HART0/rdin_reg[26]} {HART0/rdin_reg[27]} {HART0/rdin_reg[28]} {HART0/rdin_reg[29]} {HART0/rdin_reg[2]} {HART0/rdin_reg[30]} {HART0/rdin_reg[31]} {HART0/rdin_reg[3]} {HART0/rdin_reg[4]} {HART0/rdin_reg[5]} {HART0/rdin_reg[6]} {HART0/rdin_reg[7]} {HART0/rdin_reg[8]} {HART0/rdin_reg[9]} HART0/ren_reg {HART0/retired[0]_i_2} {HART0/retired_reg[0]} {HART0/retired_reg[0]_i_1} {HART0/retired_reg[10]} {HART0/retired_reg[11]} {HART0/retired_reg[12]} {HART0/retired_reg[12]_i_1} {HART0/retired_reg[13]} {HART0/retired_reg[14]} {HART0/retired_reg[15]} {HART0/retired_reg[16]} {HART0/retired_reg[16]_i_1} {HART0/retired_reg[17]} {HART0/retired_reg[18]} {HART0/retired_reg[19]} {HART0/retired_reg[1]} {HART0/retired_reg[20]} {HART0/retired_reg[20]_i_1} {HART0/retired_reg[21]} {HART0/retired_reg[22]} {HART0/retired_reg[23]} {HART0/retired_reg[24]} {HART0/retired_reg[24]_i_1} {HART0/retired_reg[25]} {HART0/retired_reg[26]} {HART0/retired_reg[27]} {HART0/retired_reg[28]} {HART0/retired_reg[28]_i_1} {HART0/retired_reg[29]} {HART0/retired_reg[2]} {HART0/retired_reg[30]} {HART0/retired_reg[31]} {HART0/retired_reg[32]} {HART0/retired_reg[32]_i_1} {HART0/retired_reg[33]} {HART0/retired_reg[34]} {HART0/retired_reg[35]} {HART0/retired_reg[36]} {HART0/retired_reg[36]_i_1} {HART0/retired_reg[37]} {HART0/retired_reg[38]} {HART0/retired_reg[39]} {HART0/retired_reg[3]} {HART0/retired_reg[40]} {HART0/retired_reg[40]_i_1} {HART0/retired_reg[41]} {HART0/retired_reg[42]} {HART0/retired_reg[43]} {HART0/retired_reg[44]} {HART0/retired_reg[44]_i_1} {HART0/retired_reg[45]} {HART0/retired_reg[46]} {HART0/retired_reg[47]} {HART0/retired_reg[48]} {HART0/retired_reg[48]_i_1} {HART0/retired_reg[49]} {HART0/retired_reg[4]} {HART0/retired_reg[4]_i_1} {HART0/retired_reg[50]} {HART0/retired_reg[51]} {HART0/retired_reg[52]} {HART0/retired_reg[52]_i_1} {HART0/retired_reg[53]} {HART0/retired_reg[54]} {HART0/retired_reg[55]} {HART0/retired_reg[56]} {HART0/retired_reg[56]_i_1} {HART0/retired_reg[57]} {HART0/retired_reg[58]} {HART0/retired_reg[59]} {HART0/retired_reg[5]} {HART0/retired_reg[60]} {HART0/retired_reg[60]_i_1} {HART0/retired_reg[61]} {HART0/retired_reg[62]} {HART0/retired_reg[63]} {HART0/retired_reg[6]} {HART0/retired_reg[7]} {HART0/retired_reg[8]} {HART0/retired_reg[8]_i_1} {HART0/retired_reg[9]} {HART0/rwaddress_reg[0]} {HART0/rwaddress_reg[10]} {HART0/rwaddress_reg[11]} {HART0/rwaddress_reg[12]} {HART0/rwaddress_reg[13]} {HART0/rwaddress_reg[14]} {HART0/rwaddress_reg[15]} {HART0/rwaddress_reg[16]} {HART0/rwaddress_reg[17]} {HART0/rwaddress_reg[18]} {HART0/rwaddress_reg[19]} {HART0/rwaddress_reg[1]} {HART0/rwaddress_reg[20]} {HART0/rwaddress_reg[21]} {HART0/rwaddress_reg[22]} {HART0/rwaddress_reg[23]} {HART0/rwaddress_reg[24]} {HART0/rwaddress_reg[25]} {HART0/rwaddress_reg[26]} {HART0/rwaddress_reg[27]} {HART0/rwaddress_reg[28]} {HART0/rwaddress_reg[29]} {HART0/rwaddress_reg[2]} {HART0/rwaddress_reg[30]} {HART0/rwaddress_reg[31]} {HART0/rwaddress_reg[3]} {HART0/rwaddress_reg[4]} {HART0/rwaddress_reg[5]} {HART0/rwaddress_reg[6]} {HART0/rwaddress_reg[7]} {HART0/rwaddress_reg[8]} {HART0/rwaddress_reg[9]} HART0/rwe_i_7 HART0/rwe_reg {HART0/wstrb_reg[0]} {HART0/wstrb_reg[1]} {HART0/wstrb_reg[2]} {HART0/wstrb_reg[3]}}]
resize_pblock [get_pblocks pblock_HART0] -add {SLICE_X84Y100:SLICE_X109Y149}
resize_pblock [get_pblocks pblock_HART0] -add {DSP48_X5Y40:DSP48_X6Y59}
resize_pblock [get_pblocks pblock_HART0] -add {RAMB18_X5Y40:RAMB18_X6Y59}
resize_pblock [get_pblocks pblock_HART0] -add {RAMB36_X5Y20:RAMB36_X6Y29}
create_pblock pblock_FPU
add_cells_to_pblock [get_pblocks pblock_FPU] [get_cells -quiet [list HART0/FPU]]
resize_pblock [get_pblocks pblock_FPU] -add {SLICE_X120Y100:SLICE_X151Y149}
resize_pblock [get_pblocks pblock_FPU] -add {DSP48_X7Y40:DSP48_X7Y59}
resize_pblock [get_pblocks pblock_FPU] -add {RAMB18_X7Y40:RAMB18_X7Y59}
resize_pblock [get_pblocks pblock_FPU] -add {RAMB36_X7Y20:RAMB36_X7Y29}
create_pblock pblock_HART1
add_cells_to_pblock [get_pblocks pblock_HART1] [get_cells -quiet [list HART1]]
resize_pblock [get_pblocks pblock_HART1] -add {SLICE_X66Y100:SLICE_X83Y149}
resize_pblock [get_pblocks pblock_HART1] -add {DSP48_X4Y40:DSP48_X4Y59}
resize_pblock [get_pblocks pblock_HART1] -add {RAMB18_X4Y40:RAMB18_X4Y59}
resize_pblock [get_pblocks pblock_HART1] -add {RAMB36_X4Y20:RAMB36_X4Y29}
create_pblock pblock_HART2
add_cells_to_pblock [get_pblocks pblock_HART2] [get_cells -quiet [list HART2]]
resize_pblock [get_pblocks pblock_HART2] -add {SLICE_X44Y100:SLICE_X61Y149}
resize_pblock [get_pblocks pblock_HART2] -add {DSP48_X2Y40:DSP48_X2Y59}
resize_pblock [get_pblocks pblock_HART2] -add {RAMB18_X3Y40:RAMB18_X3Y59}
resize_pblock [get_pblocks pblock_HART2] -add {RAMB36_X3Y20:RAMB36_X3Y29}
create_pblock pblock_HART3
add_cells_to_pblock [get_pblocks pblock_HART3] [get_cells -quiet [list HART3]]
resize_pblock [get_pblocks pblock_HART3] -add {SLICE_X66Y50:SLICE_X83Y99}
resize_pblock [get_pblocks pblock_HART3] -add {DSP48_X4Y20:DSP48_X4Y39}
resize_pblock [get_pblocks pblock_HART3] -add {RAMB18_X4Y20:RAMB18_X4Y39}
resize_pblock [get_pblocks pblock_HART3] -add {RAMB36_X4Y10:RAMB36_X4Y19}
create_pblock pblock_HART4
add_cells_to_pblock [get_pblocks pblock_HART4] [get_cells -quiet [list HART4]]
resize_pblock [get_pblocks pblock_HART4] -add {SLICE_X44Y50:SLICE_X61Y99}
resize_pblock [get_pblocks pblock_HART4] -add {DSP48_X2Y20:DSP48_X2Y39}
resize_pblock [get_pblocks pblock_HART4] -add {RAMB18_X3Y20:RAMB18_X3Y39}
resize_pblock [get_pblocks pblock_HART4] -add {RAMB36_X3Y10:RAMB36_X3Y19}

create_pblock pblock_GPU
add_cells_to_pblock [get_pblocks pblock_GPU] [get_cells -quiet [list UCDEVICECHAIN/GPU]]
resize_pblock [get_pblocks pblock_GPU] -add {SLICE_X114Y0:SLICE_X163Y99}
resize_pblock [get_pblocks pblock_GPU] -add {DSP48_X7Y0:DSP48_X8Y39}
resize_pblock [get_pblocks pblock_GPU] -add {RAMB18_X7Y0:RAMB18_X8Y39}
resize_pblock [get_pblocks pblock_GPU] -add {RAMB36_X7Y0:RAMB36_X8Y19}
