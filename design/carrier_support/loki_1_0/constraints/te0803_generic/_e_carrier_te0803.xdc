
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

# SPI and I2C will now be exposed through MIO, not EMIO

# Application Present Input (EMIO GPIO 0)
# These can be overridded in application-specific constraints
set_property PACKAGE_PIN F15 [get_ports APP_PRESENT_lc0 ]
set_property IOSTANDARD LVCMOS18 [get_ports APP_PRESENT_lc0 ]

# Backplane Present Input (EMIO GPIO 1)
# These can be overridded in application-specific constraints
set_property PACKAGE_PIN E15 [get_ports BKPLN_PRESENT_lc1 ]
set_property IOSTANDARD LVCMOS18 [get_ports BKPLN_PRESENT_lc1 ]

# User Button Inputs (EMIO GPIO 2&3)
# Does not exist on this carrier, routed out on FMC
# These can be overridded in application-specific constraints
set_property PACKAGE_PIN D10 [get_ports USER_BTN_0_lc2 ]
set_property IOSTANDARD LVCMOS18 [get_ports USER_BTN_0_lc2 ]
set_property PACKAGE_PIN E10 [get_ports USER_BTN_1_lc3 ]
set_property IOSTANDARD LVCMOS18 [get_ports USER_BTN_1_lc3 ]

# Temperature IC (LTC2986) Interrupt (EMIO GPIO 4)
set_property PACKAGE_PIN K12 [get_ports TEMP_INT_lc4 ]
set_property IOSTANDARD LVCMOS18 [get_ports TEMP_INT_lc4 ]

# CTRL1 (unassigned) Output (EMIO GPIO 5)
# Does not exist on this carrier, routed to SoM NC Pin
# These can be overridded in application-specific constraints
set_property PACKAGE_PIN D2 [get_ports CTRL1_lc5 ]
set_property IOSTANDARD LVCMOS18 [get_ports CTRL1_lc5 ]

# Application Peripherals nRST Output (EMIO GPIO 6)
set_property PACKAGE_PIN E7 [get_ports APP_PER_NRST_lc6 ]
set_property IOSTANDARD LVCMOS18 [get_ports APP_PER_NRST_lc6 ]

# Application (ASIC) nRST Output (EMIO GPIO 7)
set_property PACKAGE_PIN G4 [get_ports APP_NRST_lc7 ]
set_property IOSTANDARD LVCMOS18 [get_ports APP_NRST_lc7 ]

# Clock Generator nRST Output (EMIO GPIO 8)
# Does not exist on this carrier, routed out on FMC
# These can be overridded in application-specific constraints
set_property PACKAGE_PIN B10 [get_ports CLKGEN_NRST_lc8 ]
set_property IOSTANDARD LVCMOS18 [get_ports CLKGEN_NRST_lc8 ]

# Clock Generator AC Output (EMIO GPIO 9-11)
# Does not exist on this carrier, routed out on FMC
# These can be overridded in application-specific constraints
set_property PACKAGE_PIN C11 [get_ports {CLKGEN_AC_lc9_11[0]} ]
set_property PACKAGE_PIN C12 [get_ports {CLKGEN_AC_lc9_11[1]} ]
set_property PACKAGE_PIN D12 [get_ports {CLKGEN_AC_lc9_11[2]} ]
set_property IOSTANDARD LVCMOS18 [get_ports {CLKGEN_AC_lc9_11[0]} ]
set_property IOSTANDARD LVCMOS18 [get_ports {CLKGEN_AC_lc9_11[1]} ]
set_property IOSTANDARD LVCMOS18 [get_ports {CLKGEN_AC_lc9_11[2]} ]

# Temperature IC (LTC2986) nRST (EMIO GPIO 12)
set_property PACKAGE_PIN K13 [get_ports TEMP_NRST_lc12 ]
set_property IOSTANDARD LVCMOS18 [get_ports TEMP_NRST_lc12 ]

# User LEDs (EMIO GPIO 13-16)
# Does not exist on this carrier, routed out on FMC
# These can be overridded in application-specific constraints
set_property PACKAGE_PIN F10 [get_ports {ULED_lc13_16[0]} ]
set_property PACKAGE_PIN A11 [get_ports {ULED_lc13_16[1]} ]
set_property PACKAGE_PIN G11 [get_ports {ULED_lc13_16[2]} ]
set_property PACKAGE_PIN A12 [get_ports {ULED_lc13_16[3]} ]
set_property IOSTANDARD LVCMOS18 [get_ports {ULED_lc13_16[0]} ]
set_property IOSTANDARD LVCMOS18 [get_ports {ULED_lc13_16[1]} ]
set_property IOSTANDARD LVCMOS18 [get_ports {ULED_lc13_16[2]} ]
set_property IOSTANDARD LVCMOS18 [get_ports {ULED_lc13_16[3]} ]

# Application-specific GPIO (always built, EMIO GPIO 21-31)
# On this carrier have been routed to P2 PMOD (dir pins also)
# The last three pins are NC on SoM
# EMIO21 - PL3: 1
set_property PACKAGE_PIN G10 [get_ports {GPIO_APP_21_31[0]} ]
# EMIO22 - PL3: 2
set_property PACKAGE_PIN H11 [get_ports {GPIO_APP_21_31[1]} ]
# EMIO23 - PL3: 3
set_property PACKAGE_PIN H12 [get_ports {GPIO_APP_21_31[2]} ]
# EMIO24 - PL3: 4
set_property PACKAGE_PIN J12 [get_ports {GPIO_APP_21_31[3]} ]
# EMIO25 - PL3: 5
set_property PACKAGE_PIN F11 [get_ports {GPIO_APP_21_31[4]} ]
# EMIO26 - PL3: 6
set_property PACKAGE_PIN F12 [get_ports {GPIO_APP_21_31[5]} ]
# EMIO27 - PL3: 7
set_property PACKAGE_PIN A10 [get_ports {GPIO_APP_21_31[6]} ]
# EMIO28 - PL3: 8
set_property PACKAGE_PIN B11 [get_ports {GPIO_APP_21_31[7]} ]
# EMIO29 - NC
set_property PACKAGE_PIN K2 [get_ports {GPIO_APP_21_31[8]} ]
# EMIO30 - NC
set_property PACKAGE_PIN J2 [get_ports {GPIO_APP_21_31[9]} ]
# EMIO31 - NC
set_property PACKAGE_PIN C7 [get_ports {GPIO_APP_21_31[10]} ]
set_property IOSTANDARD LVCMOS18 [get_ports {GPIO_APP_21_31[0]} ]
set_property IOSTANDARD LVCMOS18 [get_ports {GPIO_APP_21_31[1]} ]
set_property IOSTANDARD LVCMOS18 [get_ports {GPIO_APP_21_31[2]} ]
set_property IOSTANDARD LVCMOS18 [get_ports {GPIO_APP_21_31[3]} ]
set_property IOSTANDARD LVCMOS18 [get_ports {GPIO_APP_21_31[4]} ]
set_property IOSTANDARD LVCMOS18 [get_ports {GPIO_APP_21_31[5]} ]
set_property IOSTANDARD LVCMOS18 [get_ports {GPIO_APP_21_31[6]} ]
set_property IOSTANDARD LVCMOS18 [get_ports {GPIO_APP_21_31[7]} ]
set_property IOSTANDARD LVCMOS18 [get_ports {GPIO_APP_21_31[8]} ]
set_property IOSTANDARD LVCMOS18 [get_ports {GPIO_APP_21_31[9]} ]
set_property IOSTANDARD LVCMOS18 [get_ports {GPIO_APP_21_31[10]} ]

# Application-specific LVDS IO (always built, EMIO GPIO 17-20)
set_property PACKAGE_PIN F2 [get_ports {GPIO_LVDS_P_17_20[0]} ]
set_property PACKAGE_PIN E2 [get_ports {GPIO_LVDS_N_17_20[0]} ]
set_property IOSTANDARD LVDS [get_ports {GPIO_LVDS_P_17_20[0]} ]
set_property IOSTANDARD LVDS [get_ports {GPIO_LVDS_N_17_20[0]} ]

set_property PACKAGE_PIN K4 [get_ports {GPIO_LVDS_P_17_20[1]} ]
set_property PACKAGE_PIN K3 [get_ports {GPIO_LVDS_N_17_20[1]} ]
set_property IOSTANDARD LVDS [get_ports {GPIO_LVDS_P_17_20[1]} ]
set_property IOSTANDARD LVDS [get_ports {GPIO_LVDS_N_17_20[1]} ]

set_property PACKAGE_PIN E5 [get_ports {GPIO_LVDS_P_17_20[2]} ]
set_property PACKAGE_PIN D5 [get_ports {GPIO_LVDS_N_17_20[2]} ]
set_property IOSTANDARD LVDS [get_ports {GPIO_LVDS_P_17_20[2]} ]
set_property IOSTANDARD LVDS [get_ports {GPIO_LVDS_N_17_20[2]} ]

set_property PACKAGE_PIN D7 [get_ports {GPIO_LVDS_P_17_20[3]} ]
set_property PACKAGE_PIN D6 [get_ports {GPIO_LVDS_N_17_20[3]} ]
set_property IOSTANDARD LVDS [get_ports {GPIO_LVDS_P_17_20[3]} ]
set_property IOSTANDARD LVDS [get_ports {GPIO_LVDS_N_17_20[3]} ]
