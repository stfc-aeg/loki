# This file will add definitions to target the GARUD project for the custom LOKI carrier board.

# Any of the unused GPIO lines can be used for this without block design
# modification (range 21-31). The last three are used in preference
# because they were routed to unused SoM pins, and the others could
# prove useful.

# Because the SPI and I2C should already have been configured to be routed out to FMC as with
# HEXITEC-MHz, for now there are no changes. This will change as more complex control is required.


set_property PACKAGE_PIN AF1 [get_ports {GPIO_APP_21_31[8]} ]
# EMIO30 - NC
set_property PACKAGE_PIN AG1 [get_ports {GPIO_APP_21_31[9]} ]


set_property PACKAGE_PIN R7 [get_ports {ZINQ_ADC_PLL_RSTN}]
set_property IOSTANDARD LVCMOS18 [get_ports {ZINQ_ADC_PLL_RSTN}]

set_property PACKAGE_PIN J5 [get_ports {ZINQ_DAC_CDN}]
set_property IOSTANDARD LVCMOS18 [get_ports {ZINQ_DAC_CDN}]

set_property PACKAGE_PIN J6 [get_ports {ZINQ_DAC_CLKIN}]
set_property IOSTANDARD LVCMOS18 [get_ports {ZINQ_DAC_CLKIN}]

set_property PACKAGE_PIN H6 [get_ports {ZINQ_DAC_DIN}]
set_property IOSTANDARD LVCMOS18 [get_ports {ZINQ_DAC_DIN}]

set_property PACKAGE_PIN H3 [get_ports {ZINQ_RR_CDN}]
set_property IOSTANDARD LVCMOS18 [get_ports {ZINQ_RR_CDN}]

set_property PACKAGE_PIN K7 [get_ports {ZINQ_RR_CLKIN}]
set_property IOSTANDARD LVCMOS18 [get_ports {ZINQ_RR_CLKIN}]

set_property PACKAGE_PIN H4 [get_ports {ZINQ_RR_DIN}]
set_property IOSTANDARD LVCMOS18 [get_ports {ZINQ_RR_DIN}]

set_property PACKAGE_PIN H7 [get_ports {ZINQ_RR_LOAD_CLKIN}]
set_property IOSTANDARD LVCMOS18 [get_ports {ZINQ_RR_LOAD_CLKIN}]

set_property PACKAGE_PIN J2 [get_ports {ZINQ_UFRC_CFG_SR_CLKIN}]
set_property IOSTANDARD LVCMOS18 [get_ports {ZINQ_UFRC_CFG_SR_CLKIN}]

set_property PACKAGE_PIN K2 [get_ports {ZINQ_UFRC_CFG_SR_DIN}]
set_property IOSTANDARD LVCMOS18 [get_ports {ZINQ_UFRC_CFG_SR_DIN}]

set_property PACKAGE_PIN T7 [get_ports {ZINQ_UFRC_CFG_SR_RST}]
set_property IOSTANDARD LVCMOS18 [get_ports {ZINQ_UFRC_CFG_SR_RST}]

set_property PACKAGE_PIN J4 [get_ports {ZINQ_UFRC_DEBUG_SR_CLKIN}]
set_property IOSTANDARD LVCMOS18 [get_ports {ZINQ_UFRC_DEBUG_SR_CLKIN}]

set_property PACKAGE_PIN P6 [get_ports {ZINQ_UFRC_DEBUG_SR_DIN}]
set_property IOSTANDARD LVCMOS18 [get_ports {ZINQ_UFRC_DEBUG_SR_DIN}]

set_property PACKAGE_PIN P7 [get_ports {ZINQ_UFRC_DEBUG_SR_RST}]
set_property IOSTANDARD LVCMOS18 [get_ports {ZINQ_UFRC_DEBUG_SR_RST}]

set_property PACKAGE_PIN K8 [get_ports {ZINQ_UFRC_PLL_RSTN}]
set_property IOSTANDARD LVCMOS18 [get_ports {ZINQ_UFRC_PLL_RSTN}]

set_property PACKAGE_PIN AB6 [get_ports {ZINQ_ADC_SEL_PHIDEL1}]
set_property IOSTANDARD LVCMOS18 [get_ports {ZINQ_ADC_SEL_PHIDEL1}]

set_property PACKAGE_PIN AC6 [get_ports {ZINQ_ADC_SEL_PHIDEL2}]
set_property IOSTANDARD LVCMOS18 [get_ports {ZINQ_ADC_SEL_PHIDEL2}]

set_property PACKAGE_PIN AB2 [get_ports {ZINQ_ADC_TEST_ENABLE}]
set_property IOSTANDARD LVCMOS18 [get_ports {ZINQ_ADC_TEST_ENABLE}]

set_property PACKAGE_PIN AE8 [get_ports {ZINQ_PGA_G0}]
set_property IOSTANDARD LVCMOS18 [get_ports {ZINQ_PGA_G0}]

set_property PACKAGE_PIN AE9 [get_ports {ZINQ_PGA_G1}]
set_property IOSTANDARD LVCMOS18 [get_ports {ZINQ_PGA_G1}]

set_property PACKAGE_PIN AD9 [get_ports {ZINQ_PGA_G2}]
set_property IOSTANDARD LVCMOS18 [get_ports {ZINQ_PGA_G2}]

set_property PACKAGE_PIN AC9 [get_ports {ZINQ_PGA_G3}]
set_property IOSTANDARD LVCMOS18 [get_ports {ZINQ_PGA_G3}]

set_property PACKAGE_PIN AB1 [get_ports {ZINQ_PHI0_1}]
set_property IOSTANDARD LVCMOS18 [get_ports {ZINQ_PHI0_1}]

set_property PACKAGE_PIN AC1 [get_ports {ZINQ_PHI1_1}]
set_property IOSTANDARD LVCMOS18 [get_ports {ZINQ_PHI1_1}]

set_property PACKAGE_PIN AB4 [get_ports {ZINQ_PHI2_0}]
set_property IOSTANDARD LVCMOS18 [get_ports {ZINQ_PHI2_0}]

set_property PACKAGE_PIN AD1 [get_ports {ZINQ_PHI2_1}]
set_property IOSTANDARD LVCMOS18 [get_ports {ZINQ_PHI2_1}]

set_property PACKAGE_PIN AB3 [get_ports {ZINQ_PHI3_0}]
set_property IOSTANDARD LVCMOS18 [get_ports {ZINQ_PHI3_0}]

set_property PACKAGE_PIN AD2 [get_ports {ZINQ_PHI3_1}]
set_property IOSTANDARD LVCMOS18 [get_ports {ZINQ_PHI3_1}]

set_property PACKAGE_PIN AC2 [get_ports {ZINQ_UFRC_INCR_ADC_BITS}]
set_property IOSTANDARD LVCMOS18 [get_ports {ZINQ_UFRC_INCR_ADC_BITS}]

set_property PACKAGE_PIN W9 [get_ports {ZINQ_ADC_SDC_RST}]
set_property IOSTANDARD LVCMOS18 [get_ports {ZINQ_ADC_SDC_RST}]

set_property PACKAGE_PIN P9 [get_ports {ZINQ_ADC_SDC_SR_CLK}]
set_property IOSTANDARD LVCMOS18 [get_ports {ZINQ_ADC_SDC_SR_CLK}]

set_property PACKAGE_PIN K5 [get_ports {ZINQ_ADC_SDC_SR_RST}]
set_property IOSTANDARD LVCMOS18 [get_ports {ZINQ_ADC_SDC_SR_RST}]

set_property PACKAGE_PIN H2 [get_ports {ZINQ_ADC_SDC_TRIG}]
set_property IOSTANDARD LVCMOS18 [get_ports {ZINQ_ADC_SDC_TRIG}]

set_property PACKAGE_PIN AH6 [get_ports {ZINQ_RESET1}]
set_property IOSTANDARD LVCMOS18 [get_ports {ZINQ_RESET1}]

set_property PACKAGE_PIN AD6 [get_ports {ZINQ_RESET2}]
set_property IOSTANDARD LVCMOS18 [get_ports {ZINQ_RESET2}]

set_property PACKAGE_PIN AE4 [get_ports {ZINQ_SAMPLE1}]
set_property IOSTANDARD LVCMOS18 [get_ports {ZINQ_SAMPLE1}]

set_property PACKAGE_PIN AB5 [get_ports {ZINQ_SAMPLE2}]
set_property IOSTANDARD LVCMOS18 [get_ports {ZINQ_SAMPLE2}]

set_property PACKAGE_PIN A9 [get_ports {ZINQ_UFRC_AURORA_CB_0}]
set_property IOSTANDARD LVCMOS18 [get_ports {ZINQ_UFRC_AURORA_CB_0}]

set_property PACKAGE_PIN A8 [get_ports {ZINQ_UFRC_AURORA_CB_1}]
set_property IOSTANDARD LVCMOS18 [get_ports {ZINQ_UFRC_AURORA_CB_1}]

set_property PACKAGE_PIN B6 [get_ports {ZINQ_UFRC_AURORA_CB_2}]
set_property IOSTANDARD LVCMOS18 [get_ports {ZINQ_UFRC_AURORA_CB_2}]

set_property PACKAGE_PIN C6 [get_ports {ZINQ_UFRC_AURORA_CB_3}]
set_property IOSTANDARD LVCMOS18 [get_ports {ZINQ_UFRC_AURORA_CB_3}]

set_property PACKAGE_PIN C1 [get_ports {ZINQ_UFRC_AURORA_LU_0}]
set_property IOSTANDARD LVCMOS18 [get_ports {ZINQ_UFRC_AURORA_LU_0}]

set_property PACKAGE_PIN B1 [get_ports {ZINQ_UFRC_AURORA_LU_1}]
set_property IOSTANDARD LVCMOS18 [get_ports {ZINQ_UFRC_AURORA_LU_1}]

set_property PACKAGE_PIN B4 [get_ports {ZINQ_UFRC_AURORA_LU_2}]
set_property IOSTANDARD LVCMOS18 [get_ports {ZINQ_UFRC_AURORA_LU_2}]

set_property PACKAGE_PIN A4 [get_ports {ZINQ_UFRC_AURORA_LU_3}]
set_property IOSTANDARD LVCMOS18 [get_ports {ZINQ_UFRC_AURORA_LU_3}]

set_property PACKAGE_PIN AH9 [get_ports {ZINQ_ADC_SDC_SR_DIN}]
set_property IOSTANDARD LVCMOS18 [get_ports {ZINQ_ADC_SDC_SR_DIN}]

set_property PACKAGE_PIN AB8 [get_ports {ZINQ_PGA_AZ}]
set_property IOSTANDARD LVCMOS18 [get_ports {ZINQ_PGA_AZ}]

set_property PACKAGE_PIN AG9 [get_ports {ZINQ_PGA_SR_1}]
set_property IOSTANDARD LVCMOS18 [get_ports {ZINQ_PGA_SR_1}]

set_property PACKAGE_PIN AE7 [get_ports {ZINQ_PGA_SR_2}]
set_property IOSTANDARD LVCMOS18 [get_ports {ZINQ_PGA_SR_2}]

set_property PACKAGE_PIN AD7 [get_ports {ZINQ_PGA_SS_1}]
set_property IOSTANDARD LVCMOS18 [get_ports {ZINQ_PGA_SS_1}]

set_property PACKAGE_PIN AC8 [get_ports {ZINQ_PGA_SS_2}]
set_property IOSTANDARD LVCMOS18 [get_ports {ZINQ_PGA_SS_2}]

set_property PACKAGE_PIN AH4 [get_ports {AB_DRAIN_EN}]
set_property IOSTANDARD LVCMOS18 [get_ports {AB_DRAIN_EN}]

set_property PACKAGE_PIN AH2 [get_ports {FF_RESET}]
set_property IOSTANDARD LVCMOS18 [get_ports {FF_RESET}]

set_property PACKAGE_PIN AH3 [get_ports {FF1_MODSEL}]
set_property IOSTANDARD LVCMOS18 [get_ports {FF1_MODSEL}]

set_property PACKAGE_PIN AG3 [get_ports {FF2_MODSEL}]
set_property IOSTANDARD LVCMOS18 [get_ports {FF2_MODSEL}]

set_property PACKAGE_PIN AG4 [get_ports {ZINQ_REG_EN}]
set_property IOSTANDARD LVCMOS18 [get_ports {ZINQ_REG_EN}]

set_property PACKAGE_PIN J7 [get_ports {ZINQ_UFRC_SER_RST}]
set_property IOSTANDARD LVCMOS18 [get_ports {ZINQ_UFRC_SER_RST}]

#nets for GPIO inputs
set_property PACKAGE_PIN G1 [get_ports {ZINQ_ADC_SR_CLK_DEBUG_0}]
set_property IOSTANDARD LVCMOS18 [get_ports {ZINQ_ADC_SR_CLK_DEBUG_0}]

set_property PACKAGE_PIN F1 [get_ports {ZINQ_ADC_SR_LOAD_DEBUG_0}]
set_property IOSTANDARD LVCMOS18 [get_ports {ZINQ_ADC_SR_LOAD_DEBUG_0}]

set_property PACKAGE_PIN B3 [get_ports {ZINQ_ADC_SR_CLK_DEBUG_1}]
set_property IOSTANDARD LVCMOS18 [get_ports {ZINQ_ADC_SR_CLK_DEBUG_1}]

set_property PACKAGE_PIN A3 [get_ports {ZINQ_ADC_SR_LOAD_DEBUG_1}]
set_property IOSTANDARD LVCMOS18 [get_ports {ZINQ_ADC_SR_LOAD_DEBUG_1}]

set_property PACKAGE_PIN A7 [get_ports {ZINQ_ADC_SR_CLK_DEBUG_2}]
set_property IOSTANDARD LVCMOS18 [get_ports {ZINQ_ADC_SR_CLK_DEBUG_2}]

set_property PACKAGE_PIN A6 [get_ports {ZINQ_ADC_SR_LOAD_DEBUG_2}]
set_property IOSTANDARD LVCMOS18 [get_ports {ZINQ_ADC_SR_LOAD_DEBUG_2}]

set_property PACKAGE_PIN B8 [get_ports {ZINQ_ADC_SR_CLK_DEBUG_3}]
set_property IOSTANDARD LVCMOS18 [get_ports {ZINQ_ADC_SR_CLK_DEBUG_3}]

set_property PACKAGE_PIN C8 [get_ports {ZINQ_ADC_SR_LOAD_DEBUG_3}]
set_property IOSTANDARD LVCMOS18 [get_ports {ZINQ_ADC_SR_LOAD_DEBUG_3}]






