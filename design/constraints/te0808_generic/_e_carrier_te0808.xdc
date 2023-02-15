
#System Controller IP
  #LED_HD SC0 J3:31
  #LED_XMOD SC17 J3:48 
  #CAN RX SC19 J3:52 B47_L2_P in
  #CAN TX SC18 J3:50 B47_L2_N out 
  #CAN S  SC16 J3:46 B47_L3_N out
set_property PACKAGE_PIN J14 [get_ports BASE_sc0]
set_property PACKAGE_PIN G13 [get_ports BASE_sc5]
set_property PACKAGE_PIN J15 [get_ports BASE_sc6]
set_property PACKAGE_PIN K15 [get_ports BASE_sc7]
set_property PACKAGE_PIN A15 [get_ports BASE_sc10_io]
set_property PACKAGE_PIN B15 [get_ports BASE_sc11]
set_property PACKAGE_PIN C13 [get_ports BASE_sc12]
set_property PACKAGE_PIN C14 [get_ports BASE_sc13]
set_property PACKAGE_PIN E13 [get_ports BASE_sc14]
set_property PACKAGE_PIN E14 [get_ports BASE_sc15]
set_property PACKAGE_PIN A13 [get_ports BASE_sc16]
set_property PACKAGE_PIN B13 [get_ports BASE_sc17]
set_property PACKAGE_PIN A14 [get_ports BASE_sc18]
set_property PACKAGE_PIN B14 [get_ports BASE_sc19]
set_property IOSTANDARD LVCMOS18 [get_ports BASE_sc0]
set_property IOSTANDARD LVCMOS18 [get_ports BASE_sc5]
set_property IOSTANDARD LVCMOS18 [get_ports BASE_sc6]
set_property IOSTANDARD LVCMOS18 [get_ports BASE_sc7]
set_property IOSTANDARD LVCMOS18 [get_ports BASE_sc10_io]
set_property IOSTANDARD LVCMOS18 [get_ports BASE_sc11]
set_property IOSTANDARD LVCMOS18 [get_ports BASE_sc12]
set_property IOSTANDARD LVCMOS18 [get_ports BASE_sc13]
set_property IOSTANDARD LVCMOS18 [get_ports BASE_sc14]
set_property IOSTANDARD LVCMOS18 [get_ports BASE_sc15]
set_property IOSTANDARD LVCMOS18 [get_ports BASE_sc16]
set_property IOSTANDARD LVCMOS18 [get_ports BASE_sc17]
set_property IOSTANDARD LVCMOS18 [get_ports BASE_sc18]
set_property IOSTANDARD LVCMOS18 [get_ports BASE_sc19]

# PLL
#set_property PACKAGE_PIN AH6 [get_ports {si570_clk_p[0]}]
#set_property IOSTANDARD LVDS [get_ports {si570_clk_p[0]}]
#set_property IOSTANDARD LVDS [get_ports {si570_clk_n[0]}]
# Clocks
#set_property PACKAGE_PIN J8 [get_ports {B229_CLK1_clk_p[0]}]
#set_property PACKAGE_PIN F25 [get_ports {B128_CLK0_clk_p[0]}]
# SFP 
#set_property PACKAGE_PIN G8 [get_ports {B230_CLK0_clk_p}]
# B230_RX3_P
#set_property PACKAGE_PIN A4 [get_ports {SFP1_rxp}]
# B230_TX3_P
#set_property PACKAGE_PIN A8 [get_ports {SFP1_txp}]
# B230_RX2_P
#set_property PACKAGE_PIN B2 [get_ports {SFP2_rxp}]
# B230_TX2_P
#set_property PACKAGE_PIN B6 [get_ports {SFP2_txp}]

# Audio Codec
#LRCLK		  J3:49 B47_L9_N
#BCLK		    J3:51 B47_L9_P
#DAC_SDATA	J3:53 B47_L7_N
#ADC_SDATA	J3:55 B47_L7_P
set_property PACKAGE_PIN G14 [get_ports I2S_lrclk ]
set_property PACKAGE_PIN G15 [get_ports I2S_bclk ]
set_property PACKAGE_PIN E15 [get_ports I2S_sdin ]
set_property PACKAGE_PIN F15 [get_ports I2S_sdout ]
set_property IOSTANDARD LVCMOS18 [get_ports I2S_lrclk ]
set_property IOSTANDARD LVCMOS18 [get_ports I2S_bclk ]
set_property IOSTANDARD LVCMOS18 [get_ports I2S_sdin ]
set_property IOSTANDARD LVCMOS18 [get_ports I2S_sdout ]

