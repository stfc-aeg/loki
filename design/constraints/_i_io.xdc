
# system controller ip
#LED_HD SC0 J3:31
#LED_XMOD SC17 J3:48 
#CAN RX SC19 J3:52 B26_L11_P
#CAN TX SC18 J3:50 B26_L11_N
#CAN S  SC16 J3:46 B26_L1_N

set_property PACKAGE_PIN G14 [get_ports BASE_sc0]
set_property PACKAGE_PIN D15 [get_ports BASE_sc5]
set_property PACKAGE_PIN H13 [get_ports BASE_sc6]
set_property PACKAGE_PIN H14 [get_ports BASE_sc7]
set_property PACKAGE_PIN A13 [get_ports BASE_sc10_io]
set_property PACKAGE_PIN B13 [get_ports BASE_sc11]
set_property PACKAGE_PIN A14 [get_ports BASE_sc12]
set_property PACKAGE_PIN B14 [get_ports BASE_sc13]
set_property PACKAGE_PIN F13 [get_ports BASE_sc14]
set_property PACKAGE_PIN G13 [get_ports BASE_sc15]
set_property PACKAGE_PIN A15 [get_ports BASE_sc16]
set_property PACKAGE_PIN B15 [get_ports BASE_sc17]
set_property PACKAGE_PIN J14 [get_ports BASE_sc18]
set_property PACKAGE_PIN K14 [get_ports BASE_sc19 ]
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

# Audio Codec
#LRCLK		  J3:49 
#BCLK		    J3:51 
#DAC_SDATA	J3:53 
#ADC_SDATA	J3:55 
set_property PACKAGE_PIN L13 [get_ports I2S_lrclk ]
set_property PACKAGE_PIN L14 [get_ports I2S_bclk ]
set_property PACKAGE_PIN E15 [get_ports I2S_sdin ]
set_property PACKAGE_PIN F15 [get_ports I2S_sdout ]
set_property IOSTANDARD LVCMOS18 [get_ports I2S_lrclk ]
set_property IOSTANDARD LVCMOS18 [get_ports I2S_bclk ]
set_property IOSTANDARD LVCMOS18 [get_ports I2S_sdin ]
set_property IOSTANDARD LVCMOS18 [get_ports I2S_sdout ]

# Custom additions
# SPI0 (General Devices)
set_property PACKAGE_PIN W8 [get_ports emio_spi0_m_o_0 ]
set_property PACKAGE_PIN Y8 [get_ports emio_spi0_m_i_0 ]
set_property PACKAGE_PIN AE3 [get_ports emio_spi0_sclk_o_0 ]
set_property PACKAGE_PIN AF3 [get_ports emio_spi0_ss_o_n_0 ]
set_property PACKAGE_PIN AC9 [get_ports emio_spi0_ss1_o_n_0 ]
set_property IOSTANDARD LVCMOS18 [get_ports emio_spi0_m_o_0 ]
set_property IOSTANDARD LVCMOS18 [get_ports emio_spi0_m_i_0 ]
set_property IOSTANDARD LVCMOS18 [get_ports emio_spi0_sclk_o_0 ]
set_property IOSTANDARD LVCMOS18 [get_ports emio_spi0_ss_o_n_0 ]
set_property IOSTANDARD LVCMOS18 [get_ports emio_spi0_ss1_o_n_0 ]
# SPI1 (ASIC)
set_property PACKAGE_PIN AE9 [get_ports emio_spi1_m_o_0 ]
set_property PACKAGE_PIN AH2 [get_ports emio_spi1_m_i_0 ]
set_property PACKAGE_PIN AH1 [get_ports emio_spi1_sclk_o_0 ]
set_property PACKAGE_PIN AE8 [get_ports emio_spi1_ss_o_n_0 ]
set_property IOSTANDARD LVCMOS18 [get_ports emio_spi1_m_o_0 ]
set_property IOSTANDARD LVCMOS18 [get_ports emio_spi1_m_i_0 ]
set_property IOSTANDARD LVCMOS18 [get_ports emio_spi1_sclk_o_0 ]
set_property IOSTANDARD LVCMOS18 [get_ports emio_spi1_ss_o_n_0 ]
# I2C1
set_property PACKAGE_PIN U8 [get_ports IIC_1_0_scl_io ]
set_property PACKAGE_PIN V8 [get_ports IIC_1_0_sda_io ]
set_property IOSTANDARD LVCMOS18 [get_ports IIC_1_0_scl_io ]
set_property IOSTANDARD LVCMOS18 [get_ports IIC_1_0_sda_io ]

#################################################################
# GPIO

#LVDS Output for (GPIO) EMIO 0
set_property PACKAGE_PIN AD7 [get_ports {EMIO_0_LVDS_P[0]}]
set_property PACKAGE_PIN AE7 [get_ports {EMIO_0_LVDS_N[0]}]
set_property IOSTANDARD LVDS [get_ports {EMIO_0_LVDS_P[0]}]
set_property IOSTANDARD LVDS [get_ports {EMIO_0_LVDS_N[0]}]

#Unpaired EMIO Pin
set_property PACKAGE_PIN AD9 [get_ports {EMIO_IO_1_11[0]} ];#EMIO 1

#Other EMIO Pins in polarity Pairs
set_property PACKAGE_PIN AD2 [get_ports {EMIO_IO_1_11[1]} ];#EMIO 2
set_property PACKAGE_PIN AD1 [get_ports {EMIO_IO_1_11[2]} ];#EMIO 3

set_property PACKAGE_PIN AB6 [get_ports {EMIO_IO_1_11[3]} ];#EMIO 4
set_property PACKAGE_PIN AC6 [get_ports {EMIO_IO_1_11[4]} ];#EMIO 5

set_property PACKAGE_PIN AH8 [get_ports {EMIO_IO_1_11[5]} ];#EMIO 6
set_property PACKAGE_PIN AH7 [get_ports {EMIO_IO_1_11[6]} ];#EMIO 7

set_property PACKAGE_PIN AF8 [get_ports {EMIO_IO_1_11[7]} ];#EMIO 8
set_property PACKAGE_PIN AG8 [get_ports {EMIO_IO_1_11[8]} ];#EMIO 9

set_property PACKAGE_PIN AG5 [get_ports {EMIO_IO_1_11[9]} ];#EMIO 10
set_property PACKAGE_PIN AG6 [get_ports {EMIO_IO_1_11[10]} ];#EMIO 11

set_property IOSTANDARD LVCMOS18 [get_ports {EMIO_IO_1_11[0]} ];#EMIO 1
set_property IOSTANDARD LVCMOS18 [get_ports {EMIO_IO_1_11[1]} ];#EMIO 2
set_property IOSTANDARD LVCMOS18 [get_ports {EMIO_IO_1_11[2]} ];#EMIO 3
set_property IOSTANDARD LVCMOS18 [get_ports {EMIO_IO_1_11[3]} ];#EMIO 4
set_property IOSTANDARD LVCMOS18 [get_ports {EMIO_IO_1_11[4]} ];#EMIO 5
set_property IOSTANDARD LVCMOS18 [get_ports {EMIO_IO_1_11[5]} ];#EMIO 6
set_property IOSTANDARD LVCMOS18 [get_ports {EMIO_IO_1_11[6]} ];#EMIO 7
set_property IOSTANDARD LVCMOS18 [get_ports {EMIO_IO_1_11[7]} ];#EMIO 8
set_property IOSTANDARD LVCMOS18 [get_ports {EMIO_IO_1_11[8]} ];#EMIO 9
set_property IOSTANDARD LVCMOS18 [get_ports {EMIO_IO_1_11[9]} ];#EMIO 10
set_property IOSTANDARD LVCMOS18 [get_ports {EMIO_IO_1_11[10]} ];#EMIO 11

# PL SYSMON XADC
#set_property PACKAGE_PIN AB1 [get_ports VAUXP0]
set_property PACKAGE_PIN C3 [get_ports VAUXP0]
set_property IOSTANDARD ANALOG [get_ports VAUXP0]
#set_property PACKAGE_PIN AC1 [get_ports VAUXN0]
set_property PACKAGE_PIN C2 [get_ports VAUXN0]
set_property IOSTANDARD ANALOG [get_ports VAUXN0]
