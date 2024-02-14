# Rebind EMIO 22 to the desired package pin
# This file will add definitions to target the HEXITEC-MHz project for the LOKI carrier board.

# Some generic control lines are already in use on standardised pins:
# - SPI
# - I2C
# - ASIC nRST
# - Backplane (Power board) and Application (COB) presence

# The periperhal enable pin will be used for ASIC_EN, the regulator enable
# HMHz ASIC_EN -> SEAF D17 -> LOKI HP_G4_L8_N -> J4:56 -> TE0803 B64_L21_N -> AF3
set_property PACKAGE_PIN AF3 [get_ports APP_NRST_lc7 ]

# Route the LVDS SYNC signal to one of the LVDS-mapped GPIO outputs (EMIO18)
# HMHz SYNC P -> C13 -> LOKI HP_G4_L5_P -> J4:38 -> B64_L16_P -> AD2
# HMHz SYNC N -> C12 -> LOKI HP_G4_L5_N -> J4:36 -> B64_L16_N -> AD1
set_property PACKAGE_PIN AD2 [get_ports {GPIO_LVDS_P_17_20[1]} ]
set_property PACKAGE_PIN AD1 [get_ports {GPIO_LVDS_N_17_20[1]} ]

# DIFF_01_P/N
# HMHz DIFF 01 P -> B7 -> LOKI HP_G5_L1_P -> J4:11 -> B65_L8_P -> J1
# HMHz DIFF 01 N -> B8 -> LOKI HP_G5_L1_N -> J4:13 -> B65_L8_N -> H1
# Route the LVDS SYNC signal to one of the LVDS-mapped GPIO outputs (EMIO19)
set_property PACKAGE_PIN J1 [get_ports {GPIO_LVDS_P_17_20[2]} ]
set_property PACKAGE_PIN H1 [get_ports {GPIO_LVDS_N_17_20[2]} ]

# DIFF_02_P/N
# HMHz DIFF 02 P -> B11 -> LOKI HP_G5_L3_P -> J4:25 -> B65_L7_P -> L1
# HMHz DIFF 02 N -> B10 -> LOKI HP_G5_L3_N -> J4:23 -> B65_L7_N -> K1
# Route the LVDS SYNC signal to one of the LVDS-mapped GPIO outputs (EMIO20)
set_property PACKAGE_PIN L1 [get_ports {GPIO_LVDS_P_17_20[3]} ]
set_property PACKAGE_PIN K1 [get_ports {GPIO_LVDS_N_17_20[3]} ]

# FireFly 1 select (EMIO GPIO 29)
# Rebind GPIO 29 to the desired package pin
# HMHz MODSEL_FF1# -> SEAF D22 -> LOKI HP_G4_L13_N -> J4:84 -> B64_L20_N -> AH3
set_property PACKAGE_PIN AH3 [get_ports {GPIO_APP_21_31[8]}]

# FireFly 2 select (EMIO GPIO 30)
# Rebind GPIO 30 to the desired package pin
# HMHz MODSEL_FF1# -> SEAF D22 -> LOKI HP_G4_L13_P -> J4:86 -> B64_L20_P -> AG3
set_property PACKAGE_PIN AG3 [get_ports {GPIO_APP_21_31[9]}]


# HV_ENABLE: the CTRL1 output pin will be used for this
# HMHz HV_ENABLE -> SEAF D16 -> LOKI HP_G4_L8_P -> J4:54 -> B64_L21_P -> AE3
set_property PACKAGE_PIN AE3 [get_ports CTRL1_lc5 ]


# SHDN (EMIO EMIO 21)
# Rebind EMIO 21 to the desired package pin
# HMHz SHDN -> SEAF D25 -> LOKI HP_G4_L15_N -> J4:96 -> B64_L10_N -> AG5
set_property PACKAGE_PIN AG5 [get_ports {GPIO_APP_21_31[0]}]

# Firefly Reset (shared) (EMIO22)
# Rebind EMIO 22 to the desired package pin
# HMHz FF_RESET# -> SEAF C19 -> LOKI HP_G4_L9_P -> J4:62 -> B64_L23_P -> AH2
set_property PACKAGE_PIN AH2 [get_ports {GPIO_APP_21_31[1]}]

# FireFly 1 Interrupt (EMIO24)
# Rebind EMIO 24 to the desired package pin
# HMHz INTERRUPT_FF1# -> SEAF C21 -> LOKI HP_G4_L11_N -> J4:72 -> B64_L13_N -> AD4
set_property PACKAGE_PIN AD4 [get_ports {GPIO_APP_21_31[3]}]

# FireFly 2 Interrupt (EMIO23)
# Rebind EMIO 23 to the desired package pin
# HMHz INTERRUPT_FF2# -> SEAF C22 -> LOKI HP_G4_L11_P -> J4:74 -> B64_L13_P -> AD5
set_property PACKAGE_PIN AD5 [get_ports {GPIO_APP_21_31[2]}]

# P_GOOD (EMIO 25)
# Rebind EMIO25 to the desired package pin
# HMHz P_GOOD -> SEAF D11 -> LOKI HP_G4_L4_N -> J4:32 -> B64_L6_N -> AC6
set_property PACKAGE_PIN AC6 [get_ports {GPIO_APP_21_31[4]}]

# T_CRIT_1V8 (EMIO 26)
# Rebind EMIO26 to the desired package pin
# HMHz T_CRIT_1V8 -> SEAF D13 -> LOKI HP_G4_L6_P -> J4:42 -> B64_L22_P -> AE2
set_property PACKAGE_PIN AE2 [get_ports {GPIO_APP_21_31[5]}]

# T_INT_1V8 (EMIO 27)
# Rebind EMIO27 to the desired package pin
# HMHz T_INT_1V8 -> SEAF D14 -> LOKI HP_G4_L6_N -> J4:44 -> B64_L22_N -> AF2
set_property PACKAGE_PIN AF2 [get_ports {GPIO_APP_21_31[6]}]

# TRIP_CLR (EMIO 28)
# Rebind EMIO28 to the desired package pin
# HMHz TRIP_CLR -> SEAF D19 -> LOKI_HP_G4_L10_N -> J4:66 -> B64_L14_N -> AC3
set_property PACKAGE_PIN AC3 [get_ports {GPIO_APP_21_31[7]}]

# TRIP_BUF (EMIO 31)
# Rebind EMIO31 to the desired package pin
# HMHz TRIP_BUF -> SEAF D20 -> LOKI HP_G4_L10_P -> J4:68 -> B64_L14_P -> AC4
set_property PACKAGE_PIN AC4 [get_ports {GPIO_APP_21_31[10]}]

# TODO ALL BELOW HERE

