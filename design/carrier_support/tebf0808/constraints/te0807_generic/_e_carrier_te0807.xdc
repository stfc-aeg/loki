
#System Controller IP

#J3:31 LED_HD
set_property PACKAGE_PIN K11 [get_ports BASE_sc0]
#J3:41
set_property PACKAGE_PIN E14 [get_ports BASE_sc5]
#J3:45
set_property PACKAGE_PIN C12 [get_ports BASE_sc6]
#J3:47
set_property PACKAGE_PIN D12 [get_ports BASE_sc7]
#J3:32
set_property PACKAGE_PIN J12 [get_ports BASE_sc10_io]
#J3:34
set_property PACKAGE_PIN K13 [get_ports BASE_sc11]
#J3:36
set_property PACKAGE_PIN A13 [get_ports BASE_sc12]
#J3:38
set_property PACKAGE_PIN A14 [get_ports BASE_sc13]
#J3:40
set_property PACKAGE_PIN E12 [get_ports BASE_sc14]
#J3:42
set_property PACKAGE_PIN F12 [get_ports BASE_sc15]
#J3:46 CAN S
set_property PACKAGE_PIN A12 [get_ports BASE_sc16]
#J3:48 LED_XMOD
set_property PACKAGE_PIN B12 [get_ports BASE_sc17]
#J3:50 CAN TX 
set_property PACKAGE_PIN B14 [get_ports BASE_sc18]
#J3:52 CAN RX 
set_property PACKAGE_PIN C14 [get_ports BASE_sc19]

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
#J4:74
#set_property PACKAGE_PIN AF15 [get_ports {si570_clk_p[0]}]
#set_property IOSTANDARD LVDS [get_ports {si570_clk_p[0]}]
#set_property IOSTANDARD LVDS [get_ports {si570_clk_n[0]}]



# Audio Codec
#LRCLK		J3:49 B47_L9_N
#BCLK		J3:51 B47_L9_P
#DAC_SDATA	J3:53 B47_L7_N
#ADC_SDATA	J3:55 B47_L7_P
set_property PACKAGE_PIN G14 [get_ports I2S_lrclk ]
set_property PACKAGE_PIN H14 [get_ports I2S_bclk ]
set_property PACKAGE_PIN C13 [get_ports I2S_sdin ]
set_property PACKAGE_PIN D14 [get_ports I2S_sdout ]
set_property IOSTANDARD LVCMOS18 [get_ports I2S_lrclk ]
set_property IOSTANDARD LVCMOS18 [get_ports I2S_bclk ]
set_property IOSTANDARD LVCMOS18 [get_ports I2S_sdin ]
set_property IOSTANDARD LVCMOS18 [get_ports I2S_sdout ]

# SPI0 (General Devices) is exposed through EMIO
set_property PACKAGE_PIN AK9 [get_ports emio_spi0_m_o_0 ]
set_property PACKAGE_PIN AK8 [get_ports emio_spi0_m_o_0 ]
set_property PACKAGE_PIN AD15 [get_ports emio_spi0_sclk_o_0 ]
set_property PACKAGE_PIN AE15 [get_ports emio_spi0_ss_o_n_0 ]
set_property PACKAGE_PIN AD19 [get_ports emio_spi0_ss1_o_n_0 ]
set_property IOSTANDARD LVCMOS18 [get_ports emio_spi0_m_o_0 ]
set_property IOSTANDARD LVCMOS18 [get_ports emio_spi0_m_i_0 ]
set_property IOSTANDARD LVCMOS18 [get_ports emio_spi0_sclk_o_0 ]
set_property IOSTANDARD LVCMOS18 [get_ports emio_spi0_ss_o_n_0 ]
set_property IOSTANDARD LVCMOS18 [get_ports emio_spi0_ss1_o_n_0 ]

# SPI1 (ASIC) is exposed through EMIO
set_property PACKAGE_PIN AG18 [get_ports emio_spi1_m_o_0 ]
set_property PACKAGE_PIN AD16 [get_ports emio_spi1_m_i_0 ]
set_property PACKAGE_PIN AC16 [get_ports emio_spi1_sclk_o_0 ]
set_property PACKAGE_PIN AH18 [get_ports emio_spi1_ss_o_n_0 ]
set_property IOSTANDARD LVCMOS18 [get_ports emio_spi1_m_o_0 ]
set_property IOSTANDARD LVCMOS18 [get_ports emio_spi1_m_i_0 ]
set_property IOSTANDARD LVCMOS18 [get_ports emio_spi1_sclk_o_0 ]
set_property IOSTANDARD LVCMOS18 [get_ports emio_spi1_ss_o_n_0 ]

# I2C1 is exposed through EMIO
set_property PACKAGE_PIN AF7 [get_ports IIC_1_0_scl_io ]
set_property PACKAGE_PIN AF8 [get_ports IIC_1_0_sda_io ]
set_property IOSTANDARD LVCMOS18 [get_ports IIC_1_0_scl_io ]
set_property IOSTANDARD LVCMOS18 [get_ports IIC_1_0_sda_io ]
