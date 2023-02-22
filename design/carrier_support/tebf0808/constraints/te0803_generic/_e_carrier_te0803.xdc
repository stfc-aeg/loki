# This file contains carrier specific constraints only.

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

# SPI0 (General Devices) is exposed through EMIO
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

# SPI1 (ASIC) is exposed through EMIO
set_property PACKAGE_PIN AE9 [get_ports emio_spi1_m_o_0 ]
set_property PACKAGE_PIN AH2 [get_ports emio_spi1_m_i_0 ]
set_property PACKAGE_PIN AH1 [get_ports emio_spi1_sclk_o_0 ]
set_property PACKAGE_PIN AE8 [get_ports emio_spi1_ss_o_n_0 ]
set_property IOSTANDARD LVCMOS18 [get_ports emio_spi1_m_o_0 ]
set_property IOSTANDARD LVCMOS18 [get_ports emio_spi1_m_i_0 ]
set_property IOSTANDARD LVCMOS18 [get_ports emio_spi1_sclk_o_0 ]
set_property IOSTANDARD LVCMOS18 [get_ports emio_spi1_ss_o_n_0 ]

# I2C1 is exposed through EMIO
set_property PACKAGE_PIN U8 [get_ports IIC_1_0_scl_io ]
set_property PACKAGE_PIN V8 [get_ports IIC_1_0_sda_io ]
set_property IOSTANDARD LVCMOS18 [get_ports IIC_1_0_scl_io ]
set_property IOSTANDARD LVCMOS18 [get_ports IIC_1_0_sda_io ]

# GPIO-operated control lines for on-carrier devices
# Override in appl xdc as necessary (in particular IOSTANDARD)
##############################################################

# Application Present Input (EMIO GPIO 0)
# Does not exist on this carrier, routed out on FMC
# These can be overridded in application-specific constraints
set_property PACKAGE_PIN AF6 [get_ports APP_PRESENT_lc0 ]
set_property IOSTANDARD LVCMOS18 [get_ports APP_PRESENT_lc0 ]

# Backplane Present Input (EMIO GPIO 1)
# Does not exist on this carrier, routed out on FMC
# These can be overridded in application-specific constraints
set_property PACKAGE_PIN AF7 [get_ports BKPLN_PRESENT_lc1 ]
set_property IOSTANDARD LVCMOS18 [get_ports BKPLN_PRESENT_lc1 ]

# User Button Inputs (EMIO GPIO 2&3)
# Does not exist on this carrier, routed out on FMC
# These can be overridded in application-specific constraints
set_property PACKAGE_PIN AF5 [get_ports USER_BTN_0_lc2 ]
set_property IOSTANDARD LVCMOS18 [get_ports USER_BTN_0_lc2 ]
set_property PACKAGE_PIN AE5 [get_ports USER_BTN_1_lc3 ]
set_property IOSTANDARD LVCMOS18 [get_ports USER_BTN_1_lc3 ]

# Temperature IC (LTC2986) Interrupt (EMIO GPIO 4)
set_property PACKAGE_PIN AG8 [get_ports TEMP_INT_lc4 ]
set_property IOSTANDARD LVCMOS18 [get_ports TEMP_INT_lc4 ]

# CTRL1 (unassigned) Output (EMIO GPIO 5)
# Does not exist on this carrier, routed to SoM NC Pin
# These can be overridded in application-specific constraints
set_property PACKAGE_PIN AG10 [get_ports CTRL1_lc5 ]
set_property IOSTANDARD LVCMOS18 [get_ports CTRL1_lc5 ]

# Application Peripherals nRST Output (EMIO GPIO 6)
set_property PACKAGE_PIN AD2 [get_ports APP_PER_NRST_lc6 ]
set_property IOSTANDARD LVCMOS18 [get_ports APP_PER_NRST_lc6 ]

# Application (ASIC) nRST Output (EMIO GPIO 7)
set_property PACKAGE_PIN AD1 [get_ports APP_NRST_lc7 ]
set_property IOSTANDARD LVCMOS18 [get_ports APP_NRST_lc7 ]

# Clock Generator nRST Output (EMIO GPIO 8)
# Does not exist on this carrier, routed out on FMC
# These can be overridded in application-specific constraints
set_property PACKAGE_PIN AC3 [get_ports CLKGEN_NRST_lc8 ]
set_property IOSTANDARD LVCMOS18 [get_ports CLKGEN_NRST_lc8 ]

# Clock Generator AC Output (EMIO GPIO 9-11)
# Does not exist on this carrier, routed out on FMC
# These can be overridded in application-specific constraints
set_property PACKAGE_PIN AC2 [get_ports {CLKGEN_AC_lc9_11[0]} ]
set_property PACKAGE_PIN AB2 [get_ports {CLKGEN_AC_lc9_11[1]} ]
set_property PACKAGE_PIN AC1 [get_ports {CLKGEN_AC_lc9_11[2]} ]
set_property IOSTANDARD LVCMOS18 [get_ports {CLKGEN_AC_lc9_11[0]} ]
set_property IOSTANDARD LVCMOS18 [get_ports {CLKGEN_AC_lc9_11[1]} ]
set_property IOSTANDARD LVCMOS18 [get_ports {CLKGEN_AC_lc9_11[2]} ]

# Temperature IC (LTC2986) nRST (EMIO GPIO 12)
set_property PACKAGE_PIN AH8 [get_ports TEMP_NRST_lc12 ]
set_property IOSTANDARD LVCMOS18 [get_ports TEMP_NRST_lc12 ]

# User LEDs (EMIO GPIO 13-16)
# Does not exist on this carrier, routed out on FMC
# These can be overridded in application-specific constraints
set_property PACKAGE_PIN AB1 [get_ports {ULED_lc13_16[0]} ]
set_property PACKAGE_PIN AH4 [get_ports {ULED_lc13_16[1]} ]
set_property PACKAGE_PIN AG4 [get_ports {ULED_lc13_16[2]} ]
set_property PACKAGE_PIN AC4 [get_ports {ULED_lc13_16[3]} ]
set_property IOSTANDARD LVCMOS18 [get_ports {ULED_lc13_16[0]} ]
set_property IOSTANDARD LVCMOS18 [get_ports {ULED_lc13_16[1]} ]
set_property IOSTANDARD LVCMOS18 [get_ports {ULED_lc13_16[2]} ]
set_property IOSTANDARD LVCMOS18 [get_ports {ULED_lc13_16[3]} ]
