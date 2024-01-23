# This file will add definitions to target the BabyD project for the TEBF0808 carrier board.

# Certain pins have already been targeted as specific control pins in the LOKI control block.
# These include:
#   - The I2C/SPI buses
#   - LVDS SYNC (EMIO 17)
#   - Temp INT (EMIO 4)
#   - Temp nRST (EMIO 12)
#   - ASIC nRST (EMIO 7)
#   - VREG_EN (EMIO 6)

# Any of the unused GPIO lines can be used for this without block design
# modification (range 21-31). The last three are used in preference
# because they were routed to unused SoM pins, and the others could
# prove useful.

# Because the SPI and I2C should already have been configured to be routed out to FMC as with
# HEXITEC-MHz, for now there are no changes. This will change as more complex control is required.

# Re-route ASIC reset signal to the BabyD specific line: main con G13 -> HP_G1_L6_N -> J1:107 -> A8 on TE0803
set_property PACKAGE_PIN A8 [get_ports APP_NRST_lc7 ]

# Route the second LVDS (EMIO18) to the BabyD Sync signal. Still requires jumpers.
set_property PACKAGE_PIN L3 [get_ports {GPIO_LVDS_P_17_20[1]} ]
set_property PACKAGE_PIN L2 [get_ports {GPIO_LVDS_N_17_20[1]} ]

# Re-route FireFly nReset signal to the BabyD specific line: main con F22 -> HP_G1_L20_N -> J1:142 -> E2 on TE0803
set_property PACKAGE_PIN E3 [get_ports {GPIO_APP_21_31[8]} ]
