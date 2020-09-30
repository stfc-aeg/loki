catch {TE::UTILS::te_msg TE_BD-0 INFO "This block design tcl-file was generate with Trenz Electronic GmbH Board Part:trenz.biz:te0803_4eg_2e_tebf0808:part0:4.0, FPGA: xczu4eg-sfvc784-2-e at 2020-01-21T13:16:32."}
catch {TE::UTILS::te_msg TE_BD-1 INFO "This block design tcl-file was modified by TE-Scripts. Modifications are labelled with comment tag  # #TE_MOD# on the Block-Design tcl-file."}

if { ![info exist TE::VERSION_CONTROL] } {
    set TE::VERSION_CONTROL true
}
################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2019.2
set current_vivado_version [version -short ]
if { [string first $scripts_vivado_version $current_vivado_version] == -1 &&  $TE::VERSION_CONTROL } {
   puts ""
   catch {common::send_msg_id "BD_TCL-109" "ERROR" "This script was generated using Vivado < $scripts_vivado_version> and is being run in < $current_vivado_version> of Vivado. Please run the script in Vivado < $scripts_vivado_version> then open the design in Vivado < $current_vivado_version>. Upgrade the design by running "Tools => Report => Report IP Status...", then run write_bd_tcl to create an updated script."}
 return 1
}

################################################################
# This is a generated script based on design: zusys
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}
}
variable script_folder
set script_folder [_tcl::get_script_folder]

################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2019.2
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   common::send_msg_id "BD_TCL-1002" "WARNING" "This script was generated using Vivado <$scripts_vivado_version> without IP versions in the create_bd_cell commands, but is now being run in <$current_vivado_version> of Vivado. There may have been major IP version changes between Vivado <$scripts_vivado_version> and <$current_vivado_version>, which could impact the parameter settings of the IPs."

}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source zusys_script.tcl

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xczu4eg-sfvc784-2-e
   set_property BOARD_PART trenz.biz:te0803_4eg_2e_tebf0808:part0:4.0 [current_project]
}


# CHANGE DESIGN NAME HERE
variable design_name
set design_name zusys

# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $design_name

# Creating design if needed
set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "Please set the variable <design_name> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name exists in project.

   if { $cur_design ne $design_name } {
      common::send_msg_id "BD_TCL-001" "INFO" "Changing value of <design_name> from <$design_name> to <$cur_design> since current design is empty."
      set design_name [get_property NAME $cur_design]
   }
   common::send_msg_id "BD_TCL-002" "INFO" "Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name exists in project.
   #    7) No opened design, design_name exists in project.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name not in project.
   #    9) Current opened design, has components, but diff names, design_name not in project.

   common::send_msg_id "BD_TCL-003" "INFO" "Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

   common::send_msg_id "BD_TCL-004" "INFO" "Making design <$design_name> as current_bd_design."
   current_bd_design $design_name

}

  # Add USER_COMMENTS on $design_name
  set_property USER_COMMENTS.comment_0 "Important TEBF0808 CPLD Update to REV07 is needed to use this RGPIO definition!!!" [get_bd_designs $design_name]
  set_property USER_COMMENTS.comment_2 "Important TEBF0808 CPLD Update to REV07 is needed to use this RGPIO definition!!!" [get_bd_designs $design_name]

common::send_msg_id "BD_TCL-005" "INFO" "Currently the variable <design_name> is equal to \"$design_name\"."

if { $nRet != 0 } {
   catch {common::send_msg_id "BD_TCL-114" "ERROR" $errMsg}
   return $nRet
}

set bCheckIPsPassed 1
##################################################################
# CHECK IPs
##################################################################
set bCheckIPs 1
if { $bCheckIPs == 1 } {
   set list_check_ips "\ 
trenz.biz:user:SC0808BF:*\
trenz.biz:user:axis_live_audio:*\
xilinx.com:ip:proc_sys_reset:*\
xilinx.com:ip:vio:*\
xilinx.com:ip:zynq_ultra_ps_e:*\
trenz.biz:user:RGPIO:*\
xilinx.com:ip:xlconcat:*\
xilinx.com:ip:xlslice:*\
"

   set list_ips_missing ""
   common::send_msg_id "BD_TCL-006" "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

   foreach ip_vlnv $list_check_ips {
      set ip_obj [get_ipdefs -all $ip_vlnv]
      if { $ip_obj eq "" } {
         lappend list_ips_missing $ip_vlnv
      }
   }

   if { $list_ips_missing ne "" } {
      catch {common::send_msg_id "BD_TCL-115" "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
      set bCheckIPsPassed 0
   }

}

if { $bCheckIPsPassed != 1 } {
  common::send_msg_id "BD_TCL-1003" "WARNING" "Will not continue with creation of design due to the error(s) above."
  return 3
}

##################################################################
# DESIGN PROCs
##################################################################


# Hierarchical cell: RGPIO
proc create_hier_cell_RGPIO { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" "create_hier_cell_RGPIO() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Master -vlnv trenz.biz:user:RGPIO_EXT_rtl:1.0 RGPIO_M_EXT

  create_bd_intf_pin -mode Master -vlnv trenz.biz:user:RGPIO_EXT_rtl:1.0 RGPIO_M_EXT1


  # Create pins
  create_bd_pin -dir I -type rst RGPIO_M_RESET_N
  create_bd_pin -dir I -type clk clk
  create_bd_pin -dir I -type clk clk1

  # Create instance: RGPIO_Master_CPLD, and set properties
  set RGPIO_Master_CPLD [ create_bd_cell -type ip -vlnv trenz.biz:user:RGPIO RGPIO_Master_CPLD ]
  set_property -dict [ list \
   CONFIG.C_TYP {0} \
 ] $RGPIO_Master_CPLD

  # Create instance: RGPIO_Slave_CPLD, and set properties
  set RGPIO_Slave_CPLD [ create_bd_cell -type ip -vlnv trenz.biz:user:RGPIO RGPIO_Slave_CPLD ]
  set_property -dict [ list \
   CONFIG.C_TYP {0} \
 ] $RGPIO_Slave_CPLD

  # Create instance: vio_rgpio, and set properties
  set vio_rgpio [ create_bd_cell -type ip -vlnv xilinx.com:ip:vio vio_rgpio ]
  set_property -dict [ list \
   CONFIG.C_NUM_PROBE_IN {20} \
   CONFIG.C_NUM_PROBE_OUT {8} \
   CONFIG.C_PROBE_OUT0_WIDTH {1} \
   CONFIG.C_PROBE_OUT1_WIDTH {1} \
   CONFIG.C_PROBE_OUT2_WIDTH {12} \
   CONFIG.C_PROBE_OUT3_WIDTH {4} \
   CONFIG.C_PROBE_OUT4_WIDTH {2} \
   CONFIG.C_PROBE_OUT5_WIDTH {6} \
   CONFIG.C_PROBE_OUT6_WIDTH {16} \
   CONFIG.C_PROBE_OUT7_WIDTH {8} \
 ] $vio_rgpio

  # Create instance: xlconcat_2, and set properties
  set xlconcat_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat xlconcat_2 ]
  set_property -dict [ list \
   CONFIG.NUM_PORTS {4} \
 ] $xlconcat_2

  # Create instance: xlconcat_3, and set properties
  set xlconcat_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat xlconcat_3 ]

  # Create instance: xlslice_0, and set properties
  set xlslice_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_0 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {23} \
   CONFIG.DIN_TO {23} \
   CONFIG.DIN_WIDTH {24} \
   CONFIG.DOUT_WIDTH {1} \
 ] $xlslice_0

  # Create instance: xlslice_1, and set properties
  set xlslice_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_1 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {22} \
   CONFIG.DIN_TO {22} \
   CONFIG.DIN_WIDTH {24} \
   CONFIG.DOUT_WIDTH {1} \
 ] $xlslice_1

  # Create instance: xlslice_2, and set properties
  set xlslice_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_2 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {21} \
   CONFIG.DIN_TO {21} \
   CONFIG.DIN_WIDTH {24} \
   CONFIG.DOUT_WIDTH {1} \
 ] $xlslice_2

  # Create instance: xlslice_3, and set properties
  set xlslice_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_3 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {20} \
   CONFIG.DIN_TO {20} \
   CONFIG.DIN_WIDTH {24} \
   CONFIG.DOUT_WIDTH {1} \
 ] $xlslice_3

  # Create instance: xlslice_4, and set properties
  set xlslice_4 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_4 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {19} \
   CONFIG.DIN_TO {19} \
   CONFIG.DIN_WIDTH {24} \
   CONFIG.DOUT_WIDTH {1} \
 ] $xlslice_4

  # Create instance: xlslice_5, and set properties
  set xlslice_5 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_5 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {18} \
   CONFIG.DIN_TO {18} \
   CONFIG.DIN_WIDTH {24} \
   CONFIG.DOUT_WIDTH {1} \
 ] $xlslice_5

  # Create instance: xlslice_6, and set properties
  set xlslice_6 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_6 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {17} \
   CONFIG.DIN_TO {17} \
   CONFIG.DIN_WIDTH {24} \
   CONFIG.DOUT_WIDTH {1} \
 ] $xlslice_6

  # Create instance: xlslice_7, and set properties
  set xlslice_7 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_7 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {16} \
   CONFIG.DIN_TO {16} \
   CONFIG.DIN_WIDTH {24} \
   CONFIG.DOUT_WIDTH {1} \
 ] $xlslice_7

  # Create instance: xlslice_8, and set properties
  set xlslice_8 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_8 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {15} \
   CONFIG.DIN_TO {13} \
   CONFIG.DIN_WIDTH {24} \
   CONFIG.DOUT_WIDTH {3} \
 ] $xlslice_8

  # Create instance: xlslice_9, and set properties
  set xlslice_9 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_9 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {12} \
   CONFIG.DIN_TO {12} \
   CONFIG.DIN_WIDTH {24} \
   CONFIG.DOUT_WIDTH {1} \
 ] $xlslice_9

  # Create instance: xlslice_10, and set properties
  set xlslice_10 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_10 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {11} \
   CONFIG.DIN_TO {8} \
   CONFIG.DIN_WIDTH {24} \
   CONFIG.DOUT_WIDTH {4} \
 ] $xlslice_10

  # Create instance: xlslice_11, and set properties
  set xlslice_11 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_11 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {7} \
   CONFIG.DIN_TO {0} \
   CONFIG.DIN_WIDTH {24} \
   CONFIG.DOUT_WIDTH {8} \
 ] $xlslice_11

  # Create instance: xlslice_12, and set properties
  set xlslice_12 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_12 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {23} \
   CONFIG.DIN_TO {12} \
   CONFIG.DIN_WIDTH {24} \
   CONFIG.DOUT_WIDTH {12} \
 ] $xlslice_12

  # Create instance: xlslice_13, and set properties
  set xlslice_13 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_13 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {11} \
   CONFIG.DIN_TO {8} \
   CONFIG.DIN_WIDTH {24} \
   CONFIG.DOUT_WIDTH {4} \
 ] $xlslice_13

  # Create instance: xlslice_14, and set properties
  set xlslice_14 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_14 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {7} \
   CONFIG.DIN_TO {6} \
   CONFIG.DIN_WIDTH {24} \
   CONFIG.DOUT_WIDTH {2} \
 ] $xlslice_14

  # Create instance: xlslice_15, and set properties
  set xlslice_15 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_15 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {5} \
   CONFIG.DIN_TO {4} \
   CONFIG.DIN_WIDTH {24} \
   CONFIG.DOUT_WIDTH {2} \
 ] $xlslice_15

  # Create instance: xlslice_16, and set properties
  set xlslice_16 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_16 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {3} \
   CONFIG.DIN_TO {3} \
   CONFIG.DIN_WIDTH {24} \
   CONFIG.DOUT_WIDTH {1} \
 ] $xlslice_16

  # Create instance: xlslice_17, and set properties
  set xlslice_17 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_17 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {2} \
   CONFIG.DIN_TO {2} \
   CONFIG.DIN_WIDTH {24} \
   CONFIG.DOUT_WIDTH {1} \
 ] $xlslice_17

  # Create instance: xlslice_18, and set properties
  set xlslice_18 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_18 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {1} \
   CONFIG.DIN_TO {1} \
   CONFIG.DIN_WIDTH {24} \
   CONFIG.DOUT_WIDTH {1} \
 ] $xlslice_18

  # Create instance: xlslice_19, and set properties
  set xlslice_19 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice xlslice_19 ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {0} \
   CONFIG.DIN_TO {0} \
   CONFIG.DIN_WIDTH {24} \
   CONFIG.DOUT_WIDTH {1} \
 ] $xlslice_19

  # Create interface connections
  connect_bd_intf_net -intf_net RGPIO_Master_CPLD_RGPIO_M_EXT [get_bd_intf_pins RGPIO_M_EXT] [get_bd_intf_pins RGPIO_Master_CPLD/RGPIO_M_EXT]
  connect_bd_intf_net -intf_net RGPIO_Slave_CPLD_RGPIO_M_EXT [get_bd_intf_pins RGPIO_M_EXT1] [get_bd_intf_pins RGPIO_Slave_CPLD/RGPIO_M_EXT]

  # Create port connections
  connect_bd_net -net RGPIO_Master_CPLD_RGPIO_M_OUT [get_bd_pins RGPIO_Master_CPLD/RGPIO_M_OUT] [get_bd_pins xlslice_0/Din] [get_bd_pins xlslice_1/Din] [get_bd_pins xlslice_10/Din] [get_bd_pins xlslice_11/Din] [get_bd_pins xlslice_2/Din] [get_bd_pins xlslice_3/Din] [get_bd_pins xlslice_4/Din] [get_bd_pins xlslice_5/Din] [get_bd_pins xlslice_6/Din] [get_bd_pins xlslice_7/Din] [get_bd_pins xlslice_8/Din] [get_bd_pins xlslice_9/Din]
  connect_bd_net -net RGPIO_Slave_CPLD_RGPIO_M_OUT [get_bd_pins RGPIO_Slave_CPLD/RGPIO_M_OUT] [get_bd_pins xlslice_12/Din] [get_bd_pins xlslice_13/Din] [get_bd_pins xlslice_14/Din] [get_bd_pins xlslice_15/Din] [get_bd_pins xlslice_16/Din] [get_bd_pins xlslice_17/Din] [get_bd_pins xlslice_18/Din] [get_bd_pins xlslice_19/Din]
  connect_bd_net -net clk1_1 [get_bd_pins clk1] [get_bd_pins vio_rgpio/clk]
  connect_bd_net -net proc_sys_reset_0_peripheral_aresetn [get_bd_pins RGPIO_M_RESET_N] [get_bd_pins RGPIO_Master_CPLD/RGPIO_M_RESET_N] [get_bd_pins RGPIO_Slave_CPLD/RGPIO_M_RESET_N]
  connect_bd_net -net vio_rgpio_m_11dt8_MUX [get_bd_pins vio_rgpio/probe_in10] [get_bd_pins xlslice_10/Dout]
  connect_bd_net -net vio_rgpio_m_11dt8_muxsel [get_bd_pins vio_rgpio/probe_out3] [get_bd_pins xlconcat_2/In2]
  connect_bd_net -net vio_rgpio_m_12_CAN_FAULT [get_bd_pins vio_rgpio/probe_in9] [get_bd_pins xlslice_9/Dout]
  connect_bd_net -net vio_rgpio_m_15dt13_PHY_LEDS [get_bd_pins vio_rgpio/probe_in8] [get_bd_pins xlslice_8/Dout]
  connect_bd_net -net vio_rgpio_m_16_XMOD2BUTTON [get_bd_pins vio_rgpio/probe_in7] [get_bd_pins xlslice_7/Dout]
  connect_bd_net -net vio_rgpio_m_17_S5_3_USER [get_bd_pins vio_rgpio/probe_in6] [get_bd_pins xlslice_6/Dout]
  connect_bd_net -net vio_rgpio_m_18_S5_4_FMCVADJ [get_bd_pins vio_rgpio/probe_in5] [get_bd_pins xlslice_5/Dout]
  connect_bd_net -net vio_rgpio_m_19_reserved [get_bd_pins vio_rgpio/probe_in4] [get_bd_pins xlslice_4/Dout]
  connect_bd_net -net vio_rgpio_m_20_SD_WP [get_bd_pins vio_rgpio/probe_in3] [get_bd_pins xlslice_3/Dout]
  connect_bd_net -net vio_rgpio_m_21_FMC_CLKDIR [get_bd_pins vio_rgpio/probe_in2] [get_bd_pins xlslice_2/Dout]
  connect_bd_net -net vio_rgpio_m_22_PJTAG_TRST [get_bd_pins vio_rgpio/probe_in1] [get_bd_pins xlslice_1/Dout]
  connect_bd_net -net vio_rgpio_m_23_PJTAG_SRST [get_bd_pins vio_rgpio/probe_in0] [get_bd_pins xlslice_0/Dout]
  connect_bd_net -net vio_rgpio_m_23dt12_unused [get_bd_pins vio_rgpio/probe_out2] [get_bd_pins xlconcat_2/In3]
  connect_bd_net -net vio_rgpio_m_5dt0_leds [get_bd_pins vio_rgpio/probe_out5] [get_bd_pins xlconcat_2/In0]
  connect_bd_net -net vio_rgpio_m_7dt0_data [get_bd_pins vio_rgpio/probe_in11] [get_bd_pins xlslice_11/Dout]
  connect_bd_net -net vio_rgpio_m_7dt6_unused [get_bd_pins vio_rgpio/probe_out4] [get_bd_pins xlconcat_2/In1]
  connect_bd_net -net vio_rgpio_m_enable [get_bd_pins RGPIO_Master_CPLD/RGPIO_M_ENABLE] [get_bd_pins vio_rgpio/probe_out0]
  connect_bd_net -net vio_rgpio_s_0_S5_1_bootmode [get_bd_pins vio_rgpio/probe_in19] [get_bd_pins xlslice_19/Dout]
  connect_bd_net -net vio_rgpio_s_11dt8_bootmode [get_bd_pins vio_rgpio/probe_in13] [get_bd_pins xlslice_13/Dout]
  connect_bd_net -net vio_rgpio_s_1_S5_2_bootmode [get_bd_pins vio_rgpio/probe_in18] [get_bd_pins xlslice_18/Dout]
  connect_bd_net -net vio_rgpio_s_23dt12_PG [get_bd_pins vio_rgpio/probe_in12] [get_bd_pins xlslice_12/Dout]
  connect_bd_net -net vio_rgpio_s_23dt8_unused [get_bd_pins vio_rgpio/probe_out6] [get_bd_pins xlconcat_3/In1]
  connect_bd_net -net vio_rgpio_s_2_xmod1_button [get_bd_pins vio_rgpio/probe_in17] [get_bd_pins xlslice_17/Dout]
  connect_bd_net -net vio_rgpio_s_3_unused [get_bd_pins vio_rgpio/probe_in16] [get_bd_pins xlslice_16/Dout]
  connect_bd_net -net vio_rgpio_s_6dt5_SD_CD [get_bd_pins vio_rgpio/probe_in15] [get_bd_pins xlslice_15/Dout]
  connect_bd_net -net vio_rgpio_s_7dt0_data [get_bd_pins vio_rgpio/probe_out7] [get_bd_pins xlconcat_3/In0]
  connect_bd_net -net vio_rgpio_s_7dt6_ER_ERST [get_bd_pins vio_rgpio/probe_in14] [get_bd_pins xlslice_14/Dout]
  connect_bd_net -net vio_rgpio_s_enable [get_bd_pins RGPIO_Slave_CPLD/RGPIO_M_ENABLE] [get_bd_pins vio_rgpio/probe_out1]
  connect_bd_net -net xlconcat_2_dout [get_bd_pins RGPIO_Master_CPLD/RGPIO_M_IN] [get_bd_pins xlconcat_2/dout]
  connect_bd_net -net xlconcat_3_dout [get_bd_pins RGPIO_Slave_CPLD/RGPIO_M_IN] [get_bd_pins xlconcat_3/dout]
  connect_bd_net -net zynq_ultra_ps_e_0_pl_clk0 [get_bd_pins clk] [get_bd_pins RGPIO_Master_CPLD/RGPIO_M_USRCLK] [get_bd_pins RGPIO_Slave_CPLD/RGPIO_M_USRCLK]

  # Restore current instance
  current_bd_instance $oldCurInst
}


# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder
  variable design_name

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set BASE [ create_bd_intf_port -mode Master -vlnv xilinx.com:user:SC0808BF_bus_rtl:1.0 BASE ]

  set I2S [ create_bd_intf_port -mode Slave -vlnv trenz.biz:user:I2S_rtl:1.0 I2S ]


  # Create ports

  # Create instance: RGPIO
  create_hier_cell_RGPIO [current_bd_instance .] RGPIO

  # Create instance: SC0808BF_0, and set properties
  set SC0808BF_0 [ create_bd_cell -type ip -vlnv trenz.biz:user:SC0808BF SC0808BF_0 ]

  # Create instance: axis_live_audio_0, and set properties
  set axis_live_audio_0 [ create_bd_cell -type ip -vlnv trenz.biz:user:axis_live_audio axis_live_audio_0 ]

  # Create instance: proc_sys_reset_0, and set properties
  set proc_sys_reset_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset proc_sys_reset_0 ]

  # Create instance: vio_general, and set properties
  set vio_general [ create_bd_cell -type ip -vlnv xilinx.com:ip:vio vio_general ]
  set_property -dict [ list \
   CONFIG.C_EN_PROBE_IN_ACTIVITY {0} \
   CONFIG.C_NUM_PROBE_IN {0} \
   CONFIG.C_NUM_PROBE_OUT {3} \
 ] $vio_general

  # Create instance: zynq_ultra_ps_e_0, and set properties
  set zynq_ultra_ps_e_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:zynq_ultra_ps_e zynq_ultra_ps_e_0 ]
# #TE_MOD#_Add next line#
  apply_bd_automation -rule xilinx.com:bd_rule:zynq_ultra_ps_e -config {apply_board_preset "1" }  [get_bd_cells zynq_ultra_ps_e_0]
# #TE_MOD#_Add next line#
  set tcl_pr_ext [];if { [catch {set tcl_pr_ext [glob -join -dir ${TE::BOARDDEF_PATH}/preset_extension/ *_preset.tcl]}] } {};foreach preset_ext $tcl_pr_ext { source  $preset_ext};
# #TE_MOD#   set_property -dict [ list \
# #TE_MOD#  ] $zynq_ultra_ps_e_0

# #TE_MOD#    CONFIG.SUBPRESET1 {Custom} \
# #TE_MOD#    CONFIG.PSU__USE__AUDIO {1} \
# #TE_MOD#    CONFIG.PSU__USB__RESET__POLARITY {Active Low} \
# #TE_MOD#    CONFIG.PSU__USB__RESET__MODE {Separate MIO Pin} \
# #TE_MOD#    CONFIG.PSU__USB3_0__PERIPHERAL__IO {GT Lane1} \
# #TE_MOD#    CONFIG.PSU__USB3_0__PERIPHERAL__ENABLE {1} \
# #TE_MOD#    CONFIG.PSU__USB3_0__EMIO__ENABLE {0} \
# #TE_MOD#    CONFIG.PSU__USB2_0__EMIO__ENABLE {0} \
# #TE_MOD#    CONFIG.PSU__USB1__RESET__ENABLE {0} \
# #TE_MOD#    CONFIG.PSU__USB0__RESET__IO {MIO 30} \
# #TE_MOD#    CONFIG.PSU__USB0__RESET__ENABLE {1} \
# #TE_MOD#    CONFIG.PSU__USB0__REF_CLK_SEL {Ref Clk2} \
# #TE_MOD#    CONFIG.PSU__USB0__REF_CLK_FREQ {100} \
# #TE_MOD#    CONFIG.PSU__USB0__PERIPHERAL__IO {MIO 52 .. 63} \
# #TE_MOD#    CONFIG.PSU__USB0__PERIPHERAL__ENABLE {1} \
# #TE_MOD#    CONFIG.PSU__USB0_COHERENCY {0} \
# #TE_MOD#    CONFIG.PSU__UART0__PERIPHERAL__IO {MIO 42 .. 43} \
# #TE_MOD#    CONFIG.PSU__UART0__PERIPHERAL__ENABLE {1} \
# #TE_MOD#    CONFIG.PSU__UART0__MODEM__ENABLE {0} \
# #TE_MOD#    CONFIG.PSU__UART0__BAUD_RATE {115200} \
# #TE_MOD#    CONFIG.PSU__TTC3__WAVEOUT__ENABLE {0} \
# #TE_MOD#    CONFIG.PSU__TTC3__PERIPHERAL__ENABLE {1} \
# #TE_MOD#    CONFIG.PSU__TTC3__CLOCK__ENABLE {0} \
# #TE_MOD#    CONFIG.PSU__TTC2__WAVEOUT__ENABLE {0} \
# #TE_MOD#    CONFIG.PSU__TTC2__PERIPHERAL__ENABLE {1} \
# #TE_MOD#    CONFIG.PSU__TTC2__CLOCK__ENABLE {0} \
# #TE_MOD#    CONFIG.PSU__TTC1__WAVEOUT__ENABLE {0} \
# #TE_MOD#    CONFIG.PSU__TTC1__PERIPHERAL__ENABLE {1} \
# #TE_MOD#    CONFIG.PSU__TTC1__CLOCK__ENABLE {0} \
# #TE_MOD#    CONFIG.PSU__TTC0__WAVEOUT__ENABLE {0} \
# #TE_MOD#    CONFIG.PSU__TTC0__PERIPHERAL__ENABLE {1} \
# #TE_MOD#    CONFIG.PSU__TTC0__CLOCK__ENABLE {0} \
# #TE_MOD#    CONFIG.PSU__TSU__BUFG_PORT_PAIR {0} \
# #TE_MOD#    CONFIG.PSU__SWDT1__RESET__ENABLE {0} \
# #TE_MOD#    CONFIG.PSU__SWDT1__PERIPHERAL__ENABLE {1} \
# #TE_MOD#    CONFIG.PSU__SWDT1__CLOCK__ENABLE {0} \
# #TE_MOD#    CONFIG.PSU__SWDT0__RESET__ENABLE {0} \
# #TE_MOD#    CONFIG.PSU__SWDT0__PERIPHERAL__ENABLE {1} \
# #TE_MOD#    CONFIG.PSU__SWDT0__CLOCK__ENABLE {0} \
# #TE_MOD#    CONFIG.PSU__SD1__SLOT_TYPE {SD 2.0} \
# #TE_MOD#    CONFIG.PSU__SD1__RESET__ENABLE {0} \
# #TE_MOD#    CONFIG.PSU__SD1__PERIPHERAL__IO {MIO 46 .. 51} \
# #TE_MOD#    CONFIG.PSU__SD1__PERIPHERAL__ENABLE {1} \
# #TE_MOD#    CONFIG.PSU__SD1__GRP_WP__IO {MIO 44} \
# #TE_MOD#    CONFIG.PSU__SD1__GRP_WP__ENABLE {1} \
# #TE_MOD#    CONFIG.PSU__SD1__GRP_POW__ENABLE {0} \
# #TE_MOD#    CONFIG.PSU__SD1__GRP_CD__IO {MIO 45} \
# #TE_MOD#    CONFIG.PSU__SD1__GRP_CD__ENABLE {1} \
# #TE_MOD#    CONFIG.PSU__SD1__DATA_TRANSFER_MODE {4Bit} \
# #TE_MOD#    CONFIG.PSU__SD1_ROUTE_THROUGH_FPD {0} \
# #TE_MOD#    CONFIG.PSU__SD1_COHERENCY {0} \
# #TE_MOD#    CONFIG.PSU__SD0__SLOT_TYPE {eMMC} \
# #TE_MOD#    CONFIG.PSU__SD0__RESET__ENABLE {1} \
# #TE_MOD#    CONFIG.PSU__SD0__PERIPHERAL__IO {MIO 13 .. 22} \
# #TE_MOD#    CONFIG.PSU__SD0__PERIPHERAL__ENABLE {1} \
# #TE_MOD#    CONFIG.PSU__SD0__GRP_WP__ENABLE {0} \
# #TE_MOD#    CONFIG.PSU__SD0__GRP_POW__IO {MIO 23} \
# #TE_MOD#    CONFIG.PSU__SD0__GRP_POW__ENABLE {1} \
# #TE_MOD#    CONFIG.PSU__SD0__GRP_CD__ENABLE {0} \
# #TE_MOD#    CONFIG.PSU__SD0__DATA_TRANSFER_MODE {8Bit} \
# #TE_MOD#    CONFIG.PSU__SD0_ROUTE_THROUGH_FPD {0} \
# #TE_MOD#    CONFIG.PSU__SD0_COHERENCY {0} \
# #TE_MOD#    CONFIG.PSU__SATA__REF_CLK_SEL {Ref Clk0} \
# #TE_MOD#    CONFIG.PSU__SATA__REF_CLK_FREQ {150} \
# #TE_MOD#    CONFIG.PSU__SATA__PERIPHERAL__ENABLE {1} \
# #TE_MOD#    CONFIG.PSU__SATA__LANE1__ENABLE {0} \
# #TE_MOD#    CONFIG.PSU__SATA__LANE0__IO {GT Lane2} \
# #TE_MOD#    CONFIG.PSU__SATA__LANE0__ENABLE {1} \
# #TE_MOD#    CONFIG.PSU__QSPI__PERIPHERAL__MODE {Dual Parallel} \
# #TE_MOD#    CONFIG.PSU__QSPI__PERIPHERAL__IO {MIO 0 .. 12} \
# #TE_MOD#    CONFIG.PSU__QSPI__PERIPHERAL__ENABLE {1} \
# #TE_MOD#    CONFIG.PSU__QSPI__PERIPHERAL__DATA_MODE {x4} \
# #TE_MOD#    CONFIG.PSU__QSPI__GRP_FBCLK__IO {MIO 6} \
# #TE_MOD#    CONFIG.PSU__QSPI__GRP_FBCLK__ENABLE {1} \
# #TE_MOD#    CONFIG.PSU__QSPI_ROUTE_THROUGH_FPD {0} \
# #TE_MOD#    CONFIG.PSU__QSPI_COHERENCY {0} \
# #TE_MOD#    CONFIG.PSU__PSS_REF_CLK__FREQMHZ {33.33333} \
# #TE_MOD#    CONFIG.PSU__PROTECTION__SLAVES {LPD;USB3_1_XHCI;FE300000;FE3FFFFF;0|LPD;USB3_1;FF9E0000;FF9EFFFF;0|LPD;USB3_0_XHCI;FE200000;FE2FFFFF;1|LPD;USB3_0;FF9D0000;FF9DFFFF;1|LPD;UART1;FF010000;FF01FFFF;0|LPD;UART0;FF000000;FF00FFFF;1|LPD;TTC3;FF140000;FF14FFFF;1|LPD;TTC2;FF130000;FF13FFFF;1|LPD;TTC1;FF120000;FF12FFFF;1|LPD;TTC0;FF110000;FF11FFFF;1|FPD;SWDT1;FD4D0000;FD4DFFFF;1|LPD;SWDT0;FF150000;FF15FFFF;1|LPD;SPI1;FF050000;FF05FFFF;0|LPD;SPI0;FF040000;FF04FFFF;0|FPD;SMMU_REG;FD5F0000;FD5FFFFF;1|FPD;SMMU;FD800000;FDFFFFFF;1|FPD;SIOU;FD3D0000;FD3DFFFF;1|FPD;SERDES;FD400000;FD47FFFF;1|LPD;SD1;FF170000;FF17FFFF;1|LPD;SD0;FF160000;FF16FFFF;1|FPD;SATA;FD0C0000;FD0CFFFF;1|LPD;RTC;FFA60000;FFA6FFFF;1|LPD;RSA_CORE;FFCE0000;FFCEFFFF;1|LPD;RPU;FF9A0000;FF9AFFFF;1|LPD;R5_TCM_RAM_GLOBAL;FFE00000;FFE3FFFF;1|LPD;R5_1_Instruction_Cache;FFEC0000;FFECFFFF;1|LPD;R5_1_Data_Cache;FFED0000;FFEDFFFF;1|LPD;R5_1_BTCM_GLOBAL;FFEB0000;FFEBFFFF;1|LPD;R5_1_ATCM_GLOBAL;FFE90000;FFE9FFFF;1|LPD;R5_0_Instruction_Cache;FFE40000;FFE4FFFF;1|LPD;R5_0_Data_Cache;FFE50000;FFE5FFFF;1|LPD;R5_0_BTCM_GLOBAL;FFE20000;FFE2FFFF;1|LPD;R5_0_ATCM_GLOBAL;FFE00000;FFE0FFFF;1|LPD;QSPI_Linear_Address;C0000000;DFFFFFFF;1|LPD;QSPI;FF0F0000;FF0FFFFF;1|LPD;PMU_RAM;FFDC0000;FFDDFFFF;1|LPD;PMU_GLOBAL;FFD80000;FFDBFFFF;1|FPD;PCIE_MAIN;FD0E0000;FD0EFFFF;1|FPD;PCIE_LOW;E0000000;EFFFFFFF;1|FPD;PCIE_HIGH2;8000000000;BFFFFFFFFF;1|FPD;PCIE_HIGH1;600000000;7FFFFFFFF;1|FPD;PCIE_DMA;FD0F0000;FD0FFFFF;1|FPD;PCIE_ATTRIB;FD480000;FD48FFFF;1|LPD;OCM_XMPU_CFG;FFA70000;FFA7FFFF;1|LPD;OCM_SLCR;FF960000;FF96FFFF;1|OCM;OCM;FFFC0000;FFFFFFFF;1|LPD;NAND;FF100000;FF10FFFF;0|LPD;MBISTJTAG;FFCF0000;FFCFFFFF;1|LPD;LPD_XPPU_SINK;FF9C0000;FF9CFFFF;1|LPD;LPD_XPPU;FF980000;FF98FFFF;1|LPD;LPD_SLCR_SECURE;FF4B0000;FF4DFFFF;1|LPD;LPD_SLCR;FF410000;FF4AFFFF;1|LPD;LPD_GPV;FE100000;FE1FFFFF;1|LPD;LPD_DMA_7;FFAF0000;FFAFFFFF;1|LPD;LPD_DMA_6;FFAE0000;FFAEFFFF;1|LPD;LPD_DMA_5;FFAD0000;FFADFFFF;1|LPD;LPD_DMA_4;FFAC0000;FFACFFFF;1|LPD;LPD_DMA_3;FFAB0000;FFABFFFF;1|LPD;LPD_DMA_2;FFAA0000;FFAAFFFF;1|LPD;LPD_DMA_1;FFA90000;FFA9FFFF;1|LPD;LPD_DMA_0;FFA80000;FFA8FFFF;1|LPD;IPI_CTRL;FF380000;FF3FFFFF;1|LPD;IOU_SLCR;FF180000;FF23FFFF;1|LPD;IOU_SECURE_SLCR;FF240000;FF24FFFF;1|LPD;IOU_SCNTRS;FF260000;FF26FFFF;1|LPD;IOU_SCNTR;FF250000;FF25FFFF;1|LPD;IOU_GPV;FE000000;FE0FFFFF;1|LPD;I2C1;FF030000;FF03FFFF;0|LPD;I2C0;FF020000;FF02FFFF;1|FPD;GPU;FD4B0000;FD4BFFFF;1|LPD;GPIO;FF0A0000;FF0AFFFF;1|LPD;GEM3;FF0E0000;FF0EFFFF;1|LPD;GEM2;FF0D0000;FF0DFFFF;0|LPD;GEM1;FF0C0000;FF0CFFFF;0|LPD;GEM0;FF0B0000;FF0BFFFF;0|FPD;FPD_XMPU_SINK;FD4F0000;FD4FFFFF;1|FPD;FPD_XMPU_CFG;FD5D0000;FD5DFFFF;1|FPD;FPD_SLCR_SECURE;FD690000;FD6CFFFF;1|FPD;FPD_SLCR;FD610000;FD68FFFF;1|FPD;FPD_GPV;FD700000;FD7FFFFF;1|FPD;FPD_DMA_CH7;FD570000;FD57FFFF;1|FPD;FPD_DMA_CH6;FD560000;FD56FFFF;1|FPD;FPD_DMA_CH5;FD550000;FD55FFFF;1|FPD;FPD_DMA_CH4;FD540000;FD54FFFF;1|FPD;FPD_DMA_CH3;FD530000;FD53FFFF;1|FPD;FPD_DMA_CH2;FD520000;FD52FFFF;1|FPD;FPD_DMA_CH1;FD510000;FD51FFFF;1|FPD;FPD_DMA_CH0;FD500000;FD50FFFF;1|LPD;EFUSE;FFCC0000;FFCCFFFF;1|FPD;Display Port;FD4A0000;FD4AFFFF;1|FPD;DPDMA;FD4C0000;FD4CFFFF;1|FPD;DDR_XMPU5_CFG;FD050000;FD05FFFF;1|FPD;DDR_XMPU4_CFG;FD040000;FD04FFFF;1|FPD;DDR_XMPU3_CFG;FD030000;FD03FFFF;1|FPD;DDR_XMPU2_CFG;FD020000;FD02FFFF;1|FPD;DDR_XMPU1_CFG;FD010000;FD01FFFF;1|FPD;DDR_XMPU0_CFG;FD000000;FD00FFFF;1|FPD;DDR_QOS_CTRL;FD090000;FD09FFFF;1|FPD;DDR_PHY;FD080000;FD08FFFF;1|DDR;DDR_LOW;0;7FFFFFFF;1|DDR;DDR_HIGH;800000000;87FFFFFFF;1|FPD;DDDR_CTRL;FD070000;FD070FFF;1|LPD;Coresight;FE800000;FEFFFFFF;1|LPD;CSU_DMA;FFC80000;FFC9FFFF;1|LPD;CSU;FFCA0000;FFCAFFFF;0|LPD;CRL_APB;FF5E0000;FF85FFFF;1|FPD;CRF_APB;FD1A0000;FD2DFFFF;1|FPD;CCI_REG;FD5E0000;FD5EFFFF;1|FPD;CCI_GPV;FD6E0000;FD6EFFFF;1|LPD;CAN1;FF070000;FF07FFFF;0|LPD;CAN0;FF060000;FF06FFFF;1|FPD;APU;FD5C0000;FD5CFFFF;1|LPD;APM_INTC_IOU;FFA20000;FFA2FFFF;1|LPD;APM_FPD_LPD;FFA30000;FFA3FFFF;1|FPD;APM_5;FD490000;FD49FFFF;1|FPD;APM_0;FD0B0000;FD0BFFFF;1|LPD;APM2;FFA10000;FFA1FFFF;1|LPD;APM1;FFA00000;FFA0FFFF;1|LPD;AMS;FFA50000;FFA5FFFF;1|FPD;AFI_5;FD3B0000;FD3BFFFF;1|FPD;AFI_4;FD3A0000;FD3AFFFF;1|FPD;AFI_3;FD390000;FD39FFFF;1|FPD;AFI_2;FD380000;FD38FFFF;1|FPD;AFI_1;FD370000;FD37FFFF;1|FPD;AFI_0;FD360000;FD36FFFF;1|LPD;AFIFM6;FF9B0000;FF9BFFFF;1|FPD;ACPU_GIC;F9010000;F907FFFF;1} \
# #TE_MOD#    CONFIG.PSU__PROTECTION__MASTERS {USB1:NonSecure;0|USB0:NonSecure;1|S_AXI_LPD:NA;0|S_AXI_HPC1_FPD:NA;0|S_AXI_HPC0_FPD:NA;0|S_AXI_HP3_FPD:NA;0|S_AXI_HP2_FPD:NA;0|S_AXI_HP1_FPD:NA;0|S_AXI_HP0_FPD:NA;0|S_AXI_ACP:NA;0|S_AXI_ACE:NA;0|SD1:NonSecure;1|SD0:NonSecure;1|SATA1:NonSecure;1|SATA0:NonSecure;1|RPU1:Secure;1|RPU0:Secure;1|QSPI:NonSecure;1|PMU:NA;1|PCIe:NonSecure;1|NAND:NonSecure;0|LDMA:NonSecure;1|GPU:NonSecure;1|GEM3:NonSecure;1|GEM2:NonSecure;0|GEM1:NonSecure;0|GEM0:NonSecure;0|FDMA:NonSecure;1|DP:NonSecure;1|DAP:NA;1|Coresight:NA;1|CSU:NA;1|APU:NA;1} \
# #TE_MOD#    CONFIG.PSU__PRESET_APPLIED {1} \
# #TE_MOD#    CONFIG.PSU__PL_CLK1_BUF {TRUE} \
# #TE_MOD#    CONFIG.PSU__PJTAG__PERIPHERAL__IO {MIO 26 .. 29} \
# #TE_MOD#    CONFIG.PSU__PJTAG__PERIPHERAL__ENABLE {1} \
# #TE_MOD#    CONFIG.PSU__PCIE__VENDOR_ID {0x10EE} \
# #TE_MOD#    CONFIG.PSU__PCIE__SUBSYSTEM_VENDOR_ID {0x10EE} \
# #TE_MOD#    CONFIG.PSU__PCIE__SUBSYSTEM_ID {0x7} \
# #TE_MOD#    CONFIG.PSU__PCIE__REVISION_ID {0x0} \
# #TE_MOD#    CONFIG.PSU__PCIE__RESET__POLARITY {Active Low} \
# #TE_MOD#    CONFIG.PSU__PCIE__REF_CLK_SEL {Ref Clk2} \
# #TE_MOD#    CONFIG.PSU__PCIE__REF_CLK_FREQ {100} \
# #TE_MOD#    CONFIG.PSU__PCIE__PERIPHERAL__ROOTPORT_IO {MIO 31} \
# #TE_MOD#    CONFIG.PSU__PCIE__PERIPHERAL__ROOTPORT_ENABLE {1} \
# #TE_MOD#    CONFIG.PSU__PCIE__PERIPHERAL__ENDPOINT_IO {<Select>} \
# #TE_MOD#    CONFIG.PSU__PCIE__PERIPHERAL__ENDPOINT_ENABLE {0} \
# #TE_MOD#    CONFIG.PSU__PCIE__PERIPHERAL__ENABLE {1} \
# #TE_MOD#    CONFIG.PSU__PCIE__MSI_CAPABILITY {0} \
# #TE_MOD#    CONFIG.PSU__PCIE__MSI_64BIT_ADDR_CAPABLE {0} \
# #TE_MOD#    CONFIG.PSU__PCIE__MSIX_TABLE_SIZE {0} \
# #TE_MOD#    CONFIG.PSU__PCIE__MSIX_TABLE_OFFSET {0} \
# #TE_MOD#    CONFIG.PSU__PCIE__MSIX_PBA_OFFSET {0} \
# #TE_MOD#    CONFIG.PSU__PCIE__MSIX_PBA_BAR_INDICATOR {} \
# #TE_MOD#    CONFIG.PSU__PCIE__MSIX_CAPABILITY {0} \
# #TE_MOD#    CONFIG.PSU__PCIE__MSIX_BAR_INDICATOR {} \
# #TE_MOD#    CONFIG.PSU__PCIE__MAX_PAYLOAD_SIZE {256 bytes} \
# #TE_MOD#    CONFIG.PSU__PCIE__MAXIMUM_LINK_WIDTH {x1} \
# #TE_MOD#    CONFIG.PSU__PCIE__LINK_SPEED {5.0 Gb/s} \
# #TE_MOD#    CONFIG.PSU__PCIE__LANE3__ENABLE {0} \
# #TE_MOD#    CONFIG.PSU__PCIE__LANE2__ENABLE {0} \
# #TE_MOD#    CONFIG.PSU__PCIE__LANE1__ENABLE {0} \
# #TE_MOD#    CONFIG.PSU__PCIE__LANE0__IO {GT Lane0} \
# #TE_MOD#    CONFIG.PSU__PCIE__LANE0__ENABLE {1} \
# #TE_MOD#    CONFIG.PSU__PCIE__EROM_VAL {0x0} \
# #TE_MOD#    CONFIG.PSU__PCIE__EROM_ENABLE {0} \
# #TE_MOD#    CONFIG.PSU__PCIE__DEVICE_PORT_TYPE {Root Port} \
# #TE_MOD#    CONFIG.PSU__PCIE__DEVICE_ID {0xD021} \
# #TE_MOD#    CONFIG.PSU__PCIE__CRS_SW_VISIBILITY {0} \
# #TE_MOD#    CONFIG.PSU__PCIE__CLASS_CODE_VALUE {0x60400} \
# #TE_MOD#    CONFIG.PSU__PCIE__CLASS_CODE_SUB {0x04} \
# #TE_MOD#    CONFIG.PSU__PCIE__CLASS_CODE_INTERFACE {0x0} \
# #TE_MOD#    CONFIG.PSU__PCIE__CLASS_CODE_BASE {0x06} \
# #TE_MOD#    CONFIG.PSU__PCIE__BAR5_VAL {0x0} \
# #TE_MOD#    CONFIG.PSU__PCIE__BAR5_PREFETCHABLE {0} \
# #TE_MOD#    CONFIG.PSU__PCIE__BAR5_ENABLE {0} \
# #TE_MOD#    CONFIG.PSU__PCIE__BAR5_64BIT {0} \
# #TE_MOD#    CONFIG.PSU__PCIE__BAR4_VAL {0x0} \
# #TE_MOD#    CONFIG.PSU__PCIE__BAR4_PREFETCHABLE {0} \
# #TE_MOD#    CONFIG.PSU__PCIE__BAR4_ENABLE {0} \
# #TE_MOD#    CONFIG.PSU__PCIE__BAR4_64BIT {0} \
# #TE_MOD#    CONFIG.PSU__PCIE__BAR3_VAL {0x0} \
# #TE_MOD#    CONFIG.PSU__PCIE__BAR3_PREFETCHABLE {0} \
# #TE_MOD#    CONFIG.PSU__PCIE__BAR3_ENABLE {0} \
# #TE_MOD#    CONFIG.PSU__PCIE__BAR3_64BIT {0} \
# #TE_MOD#    CONFIG.PSU__PCIE__BAR2_VAL {0x0} \
# #TE_MOD#    CONFIG.PSU__PCIE__BAR2_PREFETCHABLE {0} \
# #TE_MOD#    CONFIG.PSU__PCIE__BAR2_ENABLE {0} \
# #TE_MOD#    CONFIG.PSU__PCIE__BAR2_64BIT {0} \
# #TE_MOD#    CONFIG.PSU__PCIE__BAR1_VAL {0x0} \
# #TE_MOD#    CONFIG.PSU__PCIE__BAR1_PREFETCHABLE {0} \
# #TE_MOD#    CONFIG.PSU__PCIE__BAR1_ENABLE {0} \
# #TE_MOD#    CONFIG.PSU__PCIE__BAR1_64BIT {0} \
# #TE_MOD#    CONFIG.PSU__PCIE__BAR0_VAL {0x0} \
# #TE_MOD#    CONFIG.PSU__PCIE__BAR0_ENABLE {0} \
# #TE_MOD#    CONFIG.PSU__IOU_SLCR__WDT_CLK_SEL__SELECT {APB} \
# #TE_MOD#    CONFIG.PSU__IOU_SLCR__WDT0__FREQMHZ {99.999985} \
# #TE_MOD#    CONFIG.PSU__IOU_SLCR__WDT0__ACT_FREQMHZ {99.999985} \
# #TE_MOD#    CONFIG.PSU__IOU_SLCR__TTC3__FREQMHZ {100.000000} \
# #TE_MOD#    CONFIG.PSU__IOU_SLCR__TTC3__ACT_FREQMHZ {100.000000} \
# #TE_MOD#    CONFIG.PSU__IOU_SLCR__TTC2__FREQMHZ {100.000000} \
# #TE_MOD#    CONFIG.PSU__IOU_SLCR__TTC2__ACT_FREQMHZ {100.000000} \
# #TE_MOD#    CONFIG.PSU__IOU_SLCR__TTC1__FREQMHZ {100.000000} \
# #TE_MOD#    CONFIG.PSU__IOU_SLCR__TTC1__ACT_FREQMHZ {100.000000} \
# #TE_MOD#    CONFIG.PSU__IOU_SLCR__TTC0__FREQMHZ {100.000000} \
# #TE_MOD#    CONFIG.PSU__IOU_SLCR__TTC0__ACT_FREQMHZ {100.000000} \
# #TE_MOD#    CONFIG.PSU__I2C0__PERIPHERAL__IO {MIO 38 .. 39} \
# #TE_MOD#    CONFIG.PSU__I2C0__PERIPHERAL__ENABLE {1} \
# #TE_MOD#    CONFIG.PSU__HIGH_ADDRESS__ENABLE {1} \
# #TE_MOD#    CONFIG.PSU__GT__VLT_SWNG_LVL_4 {0} \
# #TE_MOD#    CONFIG.PSU__GT__PRE_EMPH_LVL_4 {0} \
# #TE_MOD#    CONFIG.PSU__GT__LINK_SPEED {HBR} \
# #TE_MOD#    CONFIG.PSU__GPIO0_MIO__PERIPHERAL__ENABLE {1} \
# #TE_MOD#    CONFIG.PSU__GPIO0_MIO__IO {MIO 0 .. 25} \
# #TE_MOD#    CONFIG.PSU__GEM__TSU__ENABLE {0} \
# #TE_MOD#    CONFIG.PSU__GEM3_ROUTE_THROUGH_FPD {0} \
# #TE_MOD#    CONFIG.PSU__GEM3_COHERENCY {0} \
# #TE_MOD#    CONFIG.PSU__FPGA_PL1_ENABLE {1} \
# #TE_MOD#    CONFIG.PSU__FPD_SLCR__WDT_CLK_SEL__SELECT {APB} \
# #TE_MOD#    CONFIG.PSU__FPD_SLCR__WDT1__FREQMHZ {99.999985} \
# #TE_MOD#    CONFIG.PSU__FPD_SLCR__WDT1__ACT_FREQMHZ {99.999985} \
# #TE_MOD#    CONFIG.PSU__FPDMASTERS_COHERENCY {0} \
# #TE_MOD#    CONFIG.PSU__ENET3__TSU__ENABLE {0} \
# #TE_MOD#    CONFIG.PSU__ENET3__PTP__ENABLE {0} \
# #TE_MOD#    CONFIG.PSU__ENET3__PERIPHERAL__IO {MIO 64 .. 75} \
# #TE_MOD#    CONFIG.PSU__ENET3__PERIPHERAL__ENABLE {1} \
# #TE_MOD#    CONFIG.PSU__ENET3__GRP_MDIO__IO {MIO 76 .. 77} \
# #TE_MOD#    CONFIG.PSU__ENET3__GRP_MDIO__ENABLE {1} \
# #TE_MOD#    CONFIG.PSU__ENET3__FIFO__ENABLE {0} \
# #TE_MOD#    CONFIG.PSU__DP__REF_CLK_SEL {Ref Clk3} \
# #TE_MOD#    CONFIG.PSU__DP__REF_CLK_FREQ {27} \
# #TE_MOD#    CONFIG.PSU__DP__LANE_SEL {Single Higher} \
# #TE_MOD#    CONFIG.PSU__DPAUX__PERIPHERAL__IO {EMIO} \
# #TE_MOD#    CONFIG.PSU__DPAUX__PERIPHERAL__ENABLE {1} \
# #TE_MOD#    CONFIG.PSU__DLL__ISUSED {1} \
# #TE_MOD#    CONFIG.PSU__DISPLAYPORT__PERIPHERAL__ENABLE {1} \
# #TE_MOD#    CONFIG.PSU__DISPLAYPORT__LANE1__ENABLE {0} \
# #TE_MOD#    CONFIG.PSU__DISPLAYPORT__LANE0__IO {GT Lane3} \
# #TE_MOD#    CONFIG.PSU__DISPLAYPORT__LANE0__ENABLE {1} \
# #TE_MOD#    CONFIG.PSU__DDR__INTERFACE__FREQMHZ {600.000} \
# #TE_MOD#    CONFIG.PSU__DDR_HIGH_ADDRESS_GUI_ENABLE {1} \
# #TE_MOD#    CONFIG.PSU__DDRC__T_RP {17} \
# #TE_MOD#    CONFIG.PSU__DDRC__T_RCD {17} \
# #TE_MOD#    CONFIG.PSU__DDRC__T_RC {50} \
# #TE_MOD#    CONFIG.PSU__DDRC__T_RAS_MIN {32.0} \
# #TE_MOD#    CONFIG.PSU__DDRC__T_FAW {30.0} \
# #TE_MOD#    CONFIG.PSU__DDRC__SPEED_BIN {DDR4_2400P} \
# #TE_MOD#    CONFIG.PSU__DDRC__SB_TARGET {15-15-15} \
# #TE_MOD#    CONFIG.PSU__DDRC__ROW_ADDR_COUNT {16} \
# #TE_MOD#    CONFIG.PSU__DDRC__FGRM {1X} \
# #TE_MOD#    CONFIG.PSU__DDRC__DRAM_WIDTH {16 Bits} \
# #TE_MOD#    CONFIG.PSU__DDRC__DEVICE_CAPACITY {8192 MBits} \
# #TE_MOD#    CONFIG.PSU__DDRC__DDR4_T_REF_MODE {1} \
# #TE_MOD#    CONFIG.PSU__DDRC__CWL {16} \
# #TE_MOD#    CONFIG.PSU__DDRC__CL {17} \
# #TE_MOD#    CONFIG.PSU__DDRC__BG_ADDR_COUNT {1} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__USB3__ENABLE {1} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__USB3_DUAL_REF_CTRL__DIVISOR1 {3} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__USB3_DUAL_REF_CTRL__DIVISOR0 {25} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__USB3_DUAL_REF_CTRL__ACT_FREQMHZ {19.999996} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__USB1_BUS_REF_CTRL__DIVISOR1 {1} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__USB1_BUS_REF_CTRL__DIVISOR0 {6} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__USB0_BUS_REF_CTRL__DIVISOR1 {1} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__USB0_BUS_REF_CTRL__DIVISOR0 {6} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__USB0_BUS_REF_CTRL__ACT_FREQMHZ {249.999954} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__UART1_REF_CTRL__DIVISOR1 {1} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__UART1_REF_CTRL__DIVISOR0 {15} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__UART0_REF_CTRL__DIVISOR1 {1} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__UART0_REF_CTRL__DIVISOR0 {15} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__UART0_REF_CTRL__ACT_FREQMHZ {99.999985} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__TIMESTAMP_REF_CTRL__DIVISOR0 {1} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__TIMESTAMP_REF_CTRL__ACT_FREQMHZ {33.333328} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__SPI1_REF_CTRL__DIVISOR1 {1} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__SPI1_REF_CTRL__DIVISOR0 {7} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__SPI0_REF_CTRL__DIVISOR1 {1} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__SPI0_REF_CTRL__DIVISOR0 {7} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__SDIO1_REF_CTRL__SRCSEL {IOPLL} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__SDIO1_REF_CTRL__DIVISOR1 {1} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__SDIO1_REF_CTRL__DIVISOR0 {8} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__SDIO1_REF_CTRL__ACT_FREQMHZ {187.499969} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__SDIO0_REF_CTRL__SRCSEL {IOPLL} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__SDIO0_REF_CTRL__DIVISOR1 {1} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__SDIO0_REF_CTRL__DIVISOR0 {8} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__SDIO0_REF_CTRL__ACT_FREQMHZ {187.499969} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__RPLL_TO_FPD_CTRL__DIVISOR0 {2} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__RPLL_FRAC_CFG__ENABLED {0} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__RPLL_CTRL__FRACDATA {0.000000} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__RPLL_CTRL__FBDIV {45} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__RPLL_CTRL__DIV2 {1} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__QSPI_REF_CTRL__DIVISOR1 {1} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__QSPI_REF_CTRL__DIVISOR0 {5} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__QSPI_REF_CTRL__ACT_FREQMHZ {299.999939} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__PL3_REF_CTRL__SRCSEL {RPLL} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__PL3_REF_CTRL__DIVISOR1 {1} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__PL3_REF_CTRL__DIVISOR0 {4} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__PL2_REF_CTRL__SRCSEL {RPLL} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__PL2_REF_CTRL__DIVISOR1 {1} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__PL2_REF_CTRL__DIVISOR0 {4} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__PL1_REF_CTRL__SRCSEL {IOPLL} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__PL1_REF_CTRL__FREQMHZ {25} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__PL1_REF_CTRL__DIVISOR1 {1} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__PL1_REF_CTRL__DIVISOR0 {60} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__PL1_REF_CTRL__ACT_FREQMHZ {24.999996} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__PL0_REF_CTRL__SRCSEL {IOPLL} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__PL0_REF_CTRL__DIVISOR1 {1} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__PL0_REF_CTRL__DIVISOR0 {15} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__PL0_REF_CTRL__ACT_FREQMHZ {99.999985} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__PCAP_CTRL__DIVISOR0 {8} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__PCAP_CTRL__ACT_FREQMHZ {187.499969} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__NAND_REF_CTRL__DIVISOR1 {1} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__NAND_REF_CTRL__DIVISOR0 {15} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__LPD_SWITCH_CTRL__SRCSEL {IOPLL} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__LPD_SWITCH_CTRL__DIVISOR0 {3} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__LPD_SWITCH_CTRL__ACT_FREQMHZ {499.999908} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__LPD_LSBUS_CTRL__DIVISOR0 {15} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__LPD_LSBUS_CTRL__ACT_FREQMHZ {99.999985} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__IOU_SWITCH_CTRL__SRCSEL {IOPLL} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__IOU_SWITCH_CTRL__DIVISOR0 {6} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__IOU_SWITCH_CTRL__ACT_FREQMHZ {249.999954} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__IOPLL_TO_FPD_CTRL__DIVISOR0 {3} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__IOPLL_FRAC_CFG__ENABLED {0} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__IOPLL_CTRL__FRACDATA {0.000000} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__IOPLL_CTRL__FBDIV {90} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__IOPLL_CTRL__DIV2 {1} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__I2C1_REF_CTRL__DIVISOR1 {1} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__I2C1_REF_CTRL__DIVISOR0 {15} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__I2C0_REF_CTRL__DIVISOR1 {1} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__I2C0_REF_CTRL__DIVISOR0 {15} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__I2C0_REF_CTRL__ACT_FREQMHZ {99.999985} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__GEM_TSU_REF_CTRL__SRCSEL {IOPLL} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__GEM_TSU_REF_CTRL__DIVISOR1 {1} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__GEM_TSU_REF_CTRL__DIVISOR0 {6} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__GEM_TSU_REF_CTRL__ACT_FREQMHZ {249.999954} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__GEM3_REF_CTRL__DIVISOR1 {1} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__GEM3_REF_CTRL__DIVISOR0 {12} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__GEM3_REF_CTRL__ACT_FREQMHZ {124.999977} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__GEM2_REF_CTRL__DIVISOR1 {1} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__GEM2_REF_CTRL__DIVISOR0 {12} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__GEM1_REF_CTRL__DIVISOR1 {1} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__GEM1_REF_CTRL__DIVISOR0 {12} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__GEM0_REF_CTRL__DIVISOR1 {1} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__GEM0_REF_CTRL__DIVISOR0 {12} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__DLL_REF_CTRL__ACT_FREQMHZ {1499.999756} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__DBG_LPD_CTRL__DIVISOR0 {6} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__DBG_LPD_CTRL__ACT_FREQMHZ {249.999954} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__CPU_R5_CTRL__SRCSEL {IOPLL} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__CPU_R5_CTRL__DIVISOR0 {3} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__CPU_R5_CTRL__ACT_FREQMHZ {499.999908} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__CAN1_REF_CTRL__DIVISOR1 {1} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__CAN1_REF_CTRL__DIVISOR0 {15} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__CAN0_REF_CTRL__DIVISOR1 {1} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__CAN0_REF_CTRL__DIVISOR0 {15} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__CAN0_REF_CTRL__ACT_FREQMHZ {99.999985} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__AMS_REF_CTRL__DIVISOR1 {1} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__AMS_REF_CTRL__DIVISOR0 {30} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__AMS_REF_CTRL__ACT_FREQMHZ {49.999992} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__AFI6_REF_CTRL__DIVISOR0 {3} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__ADMA_REF_CTRL__SRCSEL {IOPLL} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__ADMA_REF_CTRL__DIVISOR0 {3} \
# #TE_MOD#    CONFIG.PSU__CRL_APB__ADMA_REF_CTRL__ACT_FREQMHZ {499.999908} \
# #TE_MOD#    CONFIG.PSU__CRF_APB__VPLL_TO_LPD_CTRL__DIVISOR0 {3} \
# #TE_MOD#    CONFIG.PSU__CRF_APB__VPLL_FRAC_CFG__ENABLED {0} \
# #TE_MOD#    CONFIG.PSU__CRF_APB__VPLL_CTRL__FRACDATA {0.000000} \
# #TE_MOD#    CONFIG.PSU__CRF_APB__VPLL_CTRL__FBDIV {90} \
# #TE_MOD#    CONFIG.PSU__CRF_APB__VPLL_CTRL__DIV2 {1} \
# #TE_MOD#    CONFIG.PSU__CRF_APB__TOPSW_MAIN_CTRL__SRCSEL {APLL} \
# #TE_MOD#    CONFIG.PSU__CRF_APB__TOPSW_MAIN_CTRL__DIVISOR0 {3} \
# #TE_MOD#    CONFIG.PSU__CRF_APB__TOPSW_MAIN_CTRL__ACT_FREQMHZ {438.888824} \
# #TE_MOD#    CONFIG.PSU__CRF_APB__TOPSW_LSBUS_CTRL__DIVISOR0 {5} \
# #TE_MOD#    CONFIG.PSU__CRF_APB__TOPSW_LSBUS_CTRL__ACT_FREQMHZ {99.999985} \
# #TE_MOD#    CONFIG.PSU__CRF_APB__SATA_REF_CTRL__SRCSEL {IOPLL} \
# #TE_MOD#    CONFIG.PSU__CRF_APB__SATA_REF_CTRL__FREQMHZ {250} \
# #TE_MOD#    CONFIG.PSU__CRF_APB__SATA_REF_CTRL__DIVISOR0 {2} \
# #TE_MOD#    CONFIG.PSU__CRF_APB__SATA_REF_CTRL__ACT_FREQMHZ {249.999954} \
# #TE_MOD#    CONFIG.PSU__CRF_APB__PCIE_REF_CTRL__SRCSEL {IOPLL} \
# #TE_MOD#    CONFIG.PSU__CRF_APB__PCIE_REF_CTRL__FREQMHZ {250} \
# #TE_MOD#    CONFIG.PSU__CRF_APB__PCIE_REF_CTRL__DIVISOR0 {2} \
# #TE_MOD#    CONFIG.PSU__CRF_APB__PCIE_REF_CTRL__ACT_FREQMHZ {249.999954} \
# #TE_MOD#    CONFIG.PSU__CRF_APB__GPU_REF_CTRL__DIVISOR0 {2} \
# #TE_MOD#    CONFIG.PSU__CRF_APB__GPU_REF_CTRL__ACT_FREQMHZ {599.999878} \
# #TE_MOD#    CONFIG.PSU__CRF_APB__GDMA_REF_CTRL__DIVISOR0 {2} \
# #TE_MOD#    CONFIG.PSU__CRF_APB__GDMA_REF_CTRL__ACT_FREQMHZ {599.999878} \
# #TE_MOD#    CONFIG.PSU__CRF_APB__DP_VIDEO__FRAC_ENABLED {0} \
# #TE_MOD#    CONFIG.PSU__CRF_APB__DP_VIDEO_REF_CTRL__SRCSEL {VPLL} \
# #TE_MOD#    CONFIG.PSU__CRF_APB__DP_VIDEO_REF_CTRL__DIVISOR1 {1} \
# #TE_MOD#    CONFIG.PSU__CRF_APB__DP_VIDEO_REF_CTRL__DIVISOR0 {5} \
# #TE_MOD#    CONFIG.PSU__CRF_APB__DP_VIDEO_REF_CTRL__ACT_FREQMHZ {299.999939} \
# #TE_MOD#    CONFIG.PSU__CRF_APB__DP_STC_REF_CTRL__SRCSEL {RPLL} \
# #TE_MOD#    CONFIG.PSU__CRF_APB__DP_STC_REF_CTRL__DIVISOR1 {1} \
# #TE_MOD#    CONFIG.PSU__CRF_APB__DP_STC_REF_CTRL__DIVISOR0 {14} \
# #TE_MOD#    CONFIG.PSU__CRF_APB__DP_STC_REF_CTRL__ACT_FREQMHZ {26.785709} \
# #TE_MOD#    CONFIG.PSU__CRF_APB__DP_AUDIO__FRAC_ENABLED {0} \
# #TE_MOD#    CONFIG.PSU__CRF_APB__DP_AUDIO_REF_CTRL__SRCSEL {RPLL} \
# #TE_MOD#    CONFIG.PSU__CRF_APB__DP_AUDIO_REF_CTRL__DIVISOR1 {1} \
# #TE_MOD#    CONFIG.PSU__CRF_APB__DP_AUDIO_REF_CTRL__DIVISOR0 {15} \
# #TE_MOD#    CONFIG.PSU__CRF_APB__DP_AUDIO_REF_CTRL__ACT_FREQMHZ {24.999996} \
# #TE_MOD#    CONFIG.PSU__CRF_APB__DPLL_TO_LPD_CTRL__DIVISOR0 {3} \
# #TE_MOD#    CONFIG.PSU__CRF_APB__DPLL_FRAC_CFG__ENABLED {0} \
# #TE_MOD#    CONFIG.PSU__CRF_APB__DPLL_CTRL__FRACDATA {0.000000} \
# #TE_MOD#    CONFIG.PSU__CRF_APB__DPLL_CTRL__FBDIV {72} \
# #TE_MOD#    CONFIG.PSU__CRF_APB__DPLL_CTRL__DIV2 {1} \
# #TE_MOD#    CONFIG.PSU__CRF_APB__DPDMA_REF_CTRL__DIVISOR0 {2} \
# #TE_MOD#    CONFIG.PSU__CRF_APB__DPDMA_REF_CTRL__ACT_FREQMHZ {599.999878} \
# #TE_MOD#    CONFIG.PSU__CRF_APB__DDR_CTRL__FREQMHZ {1200} \
# #TE_MOD#    CONFIG.PSU__CRF_APB__DDR_CTRL__DIVISOR0 {2} \
# #TE_MOD#    CONFIG.PSU__CRF_APB__DDR_CTRL__ACT_FREQMHZ {599.999878} \
# #TE_MOD#    CONFIG.PSU__CRF_APB__DBG_TSTMP_CTRL__DIVISOR0 {2} \
# #TE_MOD#    CONFIG.PSU__CRF_APB__DBG_TSTMP_CTRL__ACT_FREQMHZ {249.999954} \
# #TE_MOD#    CONFIG.PSU__CRF_APB__DBG_TRACE_CTRL__DIVISOR0 {5} \
# #TE_MOD#    CONFIG.PSU__CRF_APB__DBG_FPD_CTRL__DIVISOR0 {2} \
# #TE_MOD#    CONFIG.PSU__CRF_APB__DBG_FPD_CTRL__ACT_FREQMHZ {249.999954} \
# #TE_MOD#    CONFIG.PSU__CRF_APB__APLL_TO_LPD_CTRL__DIVISOR0 {3} \
# #TE_MOD#    CONFIG.PSU__CRF_APB__APLL_FRAC_CFG__ENABLED {0} \
# #TE_MOD#    CONFIG.PSU__CRF_APB__APLL_CTRL__FRACDATA {0.000000} \
# #TE_MOD#    CONFIG.PSU__CRF_APB__APLL_CTRL__FBDIV {79} \
# #TE_MOD#    CONFIG.PSU__CRF_APB__APLL_CTRL__DIV2 {1} \
# #TE_MOD#    CONFIG.PSU__CRF_APB__ACPU_CTRL__DIVISOR0 {1} \
# #TE_MOD#    CONFIG.PSU__CRF_APB__ACPU_CTRL__ACT_FREQMHZ {1316.666504} \
# #TE_MOD#    CONFIG.PSU__CAN0__PERIPHERAL__IO {EMIO} \
# #TE_MOD#    CONFIG.PSU__CAN0__PERIPHERAL__ENABLE {1} \
# #TE_MOD#    CONFIG.PSU__CAN0__GRP_CLK__ENABLE {0} \
# #TE_MOD#    CONFIG.PSU__ACT_DDR_FREQ_MHZ {1199.999756} \
# #TE_MOD#    CONFIG.PSU_USB3__DUAL_CLOCK_ENABLE {1} \
# #TE_MOD#    CONFIG.PSU_SD1_INTERNAL_BUS_WIDTH {4} \
# #TE_MOD#    CONFIG.PSU_SD0_INTERNAL_BUS_WIDTH {8} \
# #TE_MOD#    CONFIG.PSU_MIO_TREE_SIGNALS {sclk_out#miso_mo1#mo2#mo3#mosi_mi0#n_ss_out#clk_for_lpbk#n_ss_out_upper#mo_upper[0]#mo_upper[1]#mo_upper[2]#mo_upper[3]#sclk_out_upper#sdio0_data_out[0]#sdio0_data_out[1]#sdio0_data_out[2]#sdio0_data_out[3]#sdio0_data_out[4]#sdio0_data_out[5]#sdio0_data_out[6]#sdio0_data_out[7]#sdio0_cmd_out#sdio0_clk_out#sdio0_bus_pow#gpio0[24]#gpio0[25]#tck#tdi#tdo#tms#reset#reset_n#######scl_out#sda_out###rxd#txd#sdio1_wp#sdio1_cd_n#sdio1_data_out[0]#sdio1_data_out[1]#sdio1_data_out[2]#sdio1_data_out[3]#sdio1_cmd_out#sdio1_clk_out#ulpi_clk_in#ulpi_dir#ulpi_tx_data[2]#ulpi_nxt#ulpi_tx_data[0]#ulpi_tx_data[1]#ulpi_stp#ulpi_tx_data[3]#ulpi_tx_data[4]#ulpi_tx_data[5]#ulpi_tx_data[6]#ulpi_tx_data[7]#rgmii_tx_clk#rgmii_txd[0]#rgmii_txd[1]#rgmii_txd[2]#rgmii_txd[3]#rgmii_tx_ctl#rgmii_rx_clk#rgmii_rxd[0]#rgmii_rxd[1]#rgmii_rxd[2]#rgmii_rxd[3]#rgmii_rx_ctl#gem3_mdc#gem3_mdio_out} \
# #TE_MOD#    CONFIG.PSU_MIO_TREE_PERIPHERALS {Quad SPI Flash#Quad SPI Flash#Quad SPI Flash#Quad SPI Flash#Quad SPI Flash#Quad SPI Flash#Feedback Clk#Quad SPI Flash#Quad SPI Flash#Quad SPI Flash#Quad SPI Flash#Quad SPI Flash#Quad SPI Flash#SD 0#SD 0#SD 0#SD 0#SD 0#SD 0#SD 0#SD 0#SD 0#SD 0#SD 0#GPIO0 MIO#GPIO0 MIO#PJTAG#PJTAG#PJTAG#PJTAG#USB0 Reset#PCIE#######I2C 0#I2C 0###UART 0#UART 0#SD 1#SD 1#SD 1#SD 1#SD 1#SD 1#SD 1#SD 1#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#USB 0#Gem 3#Gem 3#Gem 3#Gem 3#Gem 3#Gem 3#Gem 3#Gem 3#Gem 3#Gem 3#Gem 3#Gem 3#MDIO 3#MDIO 3} \
# #TE_MOD#    CONFIG.PSU_MIO_9_POLARITY {Default} \
# #TE_MOD#    CONFIG.PSU_MIO_9_DIRECTION {inout} \
# #TE_MOD#    CONFIG.PSU_MIO_8_POLARITY {Default} \
# #TE_MOD#    CONFIG.PSU_MIO_8_DIRECTION {inout} \
# #TE_MOD#    CONFIG.PSU_MIO_7_POLARITY {Default} \
# #TE_MOD#    CONFIG.PSU_MIO_7_INPUT_TYPE {cmos} \
# #TE_MOD#    CONFIG.PSU_MIO_7_DIRECTION {out} \
# #TE_MOD#    CONFIG.PSU_MIO_77_POLARITY {Default} \
# #TE_MOD#    CONFIG.PSU_MIO_77_DIRECTION {inout} \
# #TE_MOD#    CONFIG.PSU_MIO_76_POLARITY {Default} \
# #TE_MOD#    CONFIG.PSU_MIO_76_INPUT_TYPE {cmos} \
# #TE_MOD#    CONFIG.PSU_MIO_76_DIRECTION {out} \
# #TE_MOD#    CONFIG.PSU_MIO_75_SLEW {fast} \
# #TE_MOD#    CONFIG.PSU_MIO_75_POLARITY {Default} \
# #TE_MOD#    CONFIG.PSU_MIO_75_DRIVE_STRENGTH {12} \
# #TE_MOD#    CONFIG.PSU_MIO_75_DIRECTION {in} \
# #TE_MOD#    CONFIG.PSU_MIO_74_SLEW {fast} \
# #TE_MOD#    CONFIG.PSU_MIO_74_POLARITY {Default} \
# #TE_MOD#    CONFIG.PSU_MIO_74_DRIVE_STRENGTH {12} \
# #TE_MOD#    CONFIG.PSU_MIO_74_DIRECTION {in} \
# #TE_MOD#    CONFIG.PSU_MIO_73_SLEW {fast} \
# #TE_MOD#    CONFIG.PSU_MIO_73_POLARITY {Default} \
# #TE_MOD#    CONFIG.PSU_MIO_73_DRIVE_STRENGTH {12} \
# #TE_MOD#    CONFIG.PSU_MIO_73_DIRECTION {in} \
# #TE_MOD#    CONFIG.PSU_MIO_72_SLEW {fast} \
# #TE_MOD#    CONFIG.PSU_MIO_72_POLARITY {Default} \
# #TE_MOD#    CONFIG.PSU_MIO_72_DRIVE_STRENGTH {12} \
# #TE_MOD#    CONFIG.PSU_MIO_72_DIRECTION {in} \
# #TE_MOD#    CONFIG.PSU_MIO_71_SLEW {fast} \
# #TE_MOD#    CONFIG.PSU_MIO_71_POLARITY {Default} \
# #TE_MOD#    CONFIG.PSU_MIO_71_DRIVE_STRENGTH {12} \
# #TE_MOD#    CONFIG.PSU_MIO_71_DIRECTION {in} \
# #TE_MOD#    CONFIG.PSU_MIO_70_SLEW {fast} \
# #TE_MOD#    CONFIG.PSU_MIO_70_POLARITY {Default} \
# #TE_MOD#    CONFIG.PSU_MIO_70_DRIVE_STRENGTH {12} \
# #TE_MOD#    CONFIG.PSU_MIO_70_DIRECTION {in} \
# #TE_MOD#    CONFIG.PSU_MIO_6_POLARITY {Default} \
# #TE_MOD#    CONFIG.PSU_MIO_6_INPUT_TYPE {cmos} \
# #TE_MOD#    CONFIG.PSU_MIO_6_DIRECTION {out} \
# #TE_MOD#    CONFIG.PSU_MIO_69_POLARITY {Default} \
# #TE_MOD#    CONFIG.PSU_MIO_69_INPUT_TYPE {cmos} \
# #TE_MOD#    CONFIG.PSU_MIO_69_DIRECTION {out} \
# #TE_MOD#    CONFIG.PSU_MIO_68_POLARITY {Default} \
# #TE_MOD#    CONFIG.PSU_MIO_68_INPUT_TYPE {cmos} \
# #TE_MOD#    CONFIG.PSU_MIO_68_DIRECTION {out} \
# #TE_MOD#    CONFIG.PSU_MIO_67_POLARITY {Default} \
# #TE_MOD#    CONFIG.PSU_MIO_67_INPUT_TYPE {cmos} \
# #TE_MOD#    CONFIG.PSU_MIO_67_DIRECTION {out} \
# #TE_MOD#    CONFIG.PSU_MIO_66_POLARITY {Default} \
# #TE_MOD#    CONFIG.PSU_MIO_66_INPUT_TYPE {cmos} \
# #TE_MOD#    CONFIG.PSU_MIO_66_DIRECTION {out} \
# #TE_MOD#    CONFIG.PSU_MIO_65_POLARITY {Default} \
# #TE_MOD#    CONFIG.PSU_MIO_65_INPUT_TYPE {cmos} \
# #TE_MOD#    CONFIG.PSU_MIO_65_DIRECTION {out} \
# #TE_MOD#    CONFIG.PSU_MIO_64_POLARITY {Default} \
# #TE_MOD#    CONFIG.PSU_MIO_64_INPUT_TYPE {cmos} \
# #TE_MOD#    CONFIG.PSU_MIO_64_DIRECTION {out} \
# #TE_MOD#    CONFIG.PSU_MIO_63_POLARITY {Default} \
# #TE_MOD#    CONFIG.PSU_MIO_63_DIRECTION {inout} \
# #TE_MOD#    CONFIG.PSU_MIO_62_POLARITY {Default} \
# #TE_MOD#    CONFIG.PSU_MIO_62_DIRECTION {inout} \
# #TE_MOD#    CONFIG.PSU_MIO_61_POLARITY {Default} \
# #TE_MOD#    CONFIG.PSU_MIO_61_DIRECTION {inout} \
# #TE_MOD#    CONFIG.PSU_MIO_60_POLARITY {Default} \
# #TE_MOD#    CONFIG.PSU_MIO_60_DIRECTION {inout} \
# #TE_MOD#    CONFIG.PSU_MIO_5_POLARITY {Default} \
# #TE_MOD#    CONFIG.PSU_MIO_5_INPUT_TYPE {cmos} \
# #TE_MOD#    CONFIG.PSU_MIO_5_DIRECTION {out} \
# #TE_MOD#    CONFIG.PSU_MIO_59_POLARITY {Default} \
# #TE_MOD#    CONFIG.PSU_MIO_59_DIRECTION {inout} \
# #TE_MOD#    CONFIG.PSU_MIO_58_POLARITY {Default} \
# #TE_MOD#    CONFIG.PSU_MIO_58_INPUT_TYPE {cmos} \
# #TE_MOD#    CONFIG.PSU_MIO_58_DIRECTION {out} \
# #TE_MOD#    CONFIG.PSU_MIO_57_POLARITY {Default} \
# #TE_MOD#    CONFIG.PSU_MIO_57_DIRECTION {inout} \
# #TE_MOD#    CONFIG.PSU_MIO_56_POLARITY {Default} \
# #TE_MOD#    CONFIG.PSU_MIO_56_DIRECTION {inout} \
# #TE_MOD#    CONFIG.PSU_MIO_55_SLEW {fast} \
# #TE_MOD#    CONFIG.PSU_MIO_55_POLARITY {Default} \
# #TE_MOD#    CONFIG.PSU_MIO_55_DRIVE_STRENGTH {12} \
# #TE_MOD#    CONFIG.PSU_MIO_55_DIRECTION {in} \
# #TE_MOD#    CONFIG.PSU_MIO_54_POLARITY {Default} \
# #TE_MOD#    CONFIG.PSU_MIO_54_DIRECTION {inout} \
# #TE_MOD#    CONFIG.PSU_MIO_53_SLEW {fast} \
# #TE_MOD#    CONFIG.PSU_MIO_53_POLARITY {Default} \
# #TE_MOD#    CONFIG.PSU_MIO_53_DRIVE_STRENGTH {12} \
# #TE_MOD#    CONFIG.PSU_MIO_53_DIRECTION {in} \
# #TE_MOD#    CONFIG.PSU_MIO_52_SLEW {fast} \
# #TE_MOD#    CONFIG.PSU_MIO_52_POLARITY {Default} \
# #TE_MOD#    CONFIG.PSU_MIO_52_DRIVE_STRENGTH {12} \
# #TE_MOD#    CONFIG.PSU_MIO_52_DIRECTION {in} \
# #TE_MOD#    CONFIG.PSU_MIO_51_PULLUPDOWN {disable} \
# #TE_MOD#    CONFIG.PSU_MIO_51_POLARITY {Default} \
# #TE_MOD#    CONFIG.PSU_MIO_51_INPUT_TYPE {cmos} \
# #TE_MOD#    CONFIG.PSU_MIO_51_DIRECTION {out} \
# #TE_MOD#    CONFIG.PSU_MIO_50_PULLUPDOWN {disable} \
# #TE_MOD#    CONFIG.PSU_MIO_50_POLARITY {Default} \
# #TE_MOD#    CONFIG.PSU_MIO_50_INPUT_TYPE {cmos} \
# #TE_MOD#    CONFIG.PSU_MIO_50_DIRECTION {inout} \
# #TE_MOD#    CONFIG.PSU_MIO_4_POLARITY {Default} \
# #TE_MOD#    CONFIG.PSU_MIO_4_DIRECTION {inout} \
# #TE_MOD#    CONFIG.PSU_MIO_49_PULLUPDOWN {disable} \
# #TE_MOD#    CONFIG.PSU_MIO_49_POLARITY {Default} \
# #TE_MOD#    CONFIG.PSU_MIO_49_INPUT_TYPE {cmos} \
# #TE_MOD#    CONFIG.PSU_MIO_49_DIRECTION {inout} \
# #TE_MOD#    CONFIG.PSU_MIO_48_PULLUPDOWN {disable} \
# #TE_MOD#    CONFIG.PSU_MIO_48_POLARITY {Default} \
# #TE_MOD#    CONFIG.PSU_MIO_48_INPUT_TYPE {cmos} \
# #TE_MOD#    CONFIG.PSU_MIO_48_DIRECTION {inout} \
# #TE_MOD#    CONFIG.PSU_MIO_47_PULLUPDOWN {disable} \
# #TE_MOD#    CONFIG.PSU_MIO_47_POLARITY {Default} \
# #TE_MOD#    CONFIG.PSU_MIO_47_INPUT_TYPE {cmos} \
# #TE_MOD#    CONFIG.PSU_MIO_47_DIRECTION {inout} \
# #TE_MOD#    CONFIG.PSU_MIO_46_PULLUPDOWN {disable} \
# #TE_MOD#    CONFIG.PSU_MIO_46_POLARITY {Default} \
# #TE_MOD#    CONFIG.PSU_MIO_46_INPUT_TYPE {cmos} \
# #TE_MOD#    CONFIG.PSU_MIO_46_DIRECTION {inout} \
# #TE_MOD#    CONFIG.PSU_MIO_45_SLEW {fast} \
# #TE_MOD#    CONFIG.PSU_MIO_45_PULLUPDOWN {disable} \
# #TE_MOD#    CONFIG.PSU_MIO_45_POLARITY {Default} \
# #TE_MOD#    CONFIG.PSU_MIO_45_INPUT_TYPE {cmos} \
# #TE_MOD#    CONFIG.PSU_MIO_45_DRIVE_STRENGTH {12} \
# #TE_MOD#    CONFIG.PSU_MIO_45_DIRECTION {in} \
# #TE_MOD#    CONFIG.PSU_MIO_44_SLEW {fast} \
# #TE_MOD#    CONFIG.PSU_MIO_44_PULLUPDOWN {disable} \
# #TE_MOD#    CONFIG.PSU_MIO_44_POLARITY {Default} \
# #TE_MOD#    CONFIG.PSU_MIO_44_INPUT_TYPE {cmos} \
# #TE_MOD#    CONFIG.PSU_MIO_44_DRIVE_STRENGTH {12} \
# #TE_MOD#    CONFIG.PSU_MIO_44_DIRECTION {in} \
# #TE_MOD#    CONFIG.PSU_MIO_43_POLARITY {Default} \
# #TE_MOD#    CONFIG.PSU_MIO_43_INPUT_TYPE {cmos} \
# #TE_MOD#    CONFIG.PSU_MIO_43_DIRECTION {out} \
# #TE_MOD#    CONFIG.PSU_MIO_42_SLEW {fast} \
# #TE_MOD#    CONFIG.PSU_MIO_42_POLARITY {Default} \
# #TE_MOD#    CONFIG.PSU_MIO_42_DRIVE_STRENGTH {12} \
# #TE_MOD#    CONFIG.PSU_MIO_42_DIRECTION {in} \
# #TE_MOD#    CONFIG.PSU_MIO_3_POLARITY {Default} \
# #TE_MOD#    CONFIG.PSU_MIO_3_DIRECTION {inout} \
# #TE_MOD#    CONFIG.PSU_MIO_39_POLARITY {Default} \
# #TE_MOD#    CONFIG.PSU_MIO_39_DIRECTION {inout} \
# #TE_MOD#    CONFIG.PSU_MIO_38_POLARITY {Default} \
# #TE_MOD#    CONFIG.PSU_MIO_38_DIRECTION {inout} \
# #TE_MOD#    CONFIG.PSU_MIO_31_POLARITY {Default} \
# #TE_MOD#    CONFIG.PSU_MIO_31_INPUT_TYPE {cmos} \
# #TE_MOD#    CONFIG.PSU_MIO_31_DIRECTION {out} \
# #TE_MOD#    CONFIG.PSU_MIO_30_POLARITY {Default} \
# #TE_MOD#    CONFIG.PSU_MIO_30_INPUT_TYPE {cmos} \
# #TE_MOD#    CONFIG.PSU_MIO_30_DIRECTION {out} \
# #TE_MOD#    CONFIG.PSU_MIO_2_POLARITY {Default} \
# #TE_MOD#    CONFIG.PSU_MIO_2_DIRECTION {inout} \
# #TE_MOD#    CONFIG.PSU_MIO_29_SLEW {fast} \
# #TE_MOD#    CONFIG.PSU_MIO_29_POLARITY {Default} \
# #TE_MOD#    CONFIG.PSU_MIO_29_DRIVE_STRENGTH {12} \
# #TE_MOD#    CONFIG.PSU_MIO_29_DIRECTION {in} \
# #TE_MOD#    CONFIG.PSU_MIO_28_POLARITY {Default} \
# #TE_MOD#    CONFIG.PSU_MIO_28_INPUT_TYPE {cmos} \
# #TE_MOD#    CONFIG.PSU_MIO_28_DIRECTION {out} \
# #TE_MOD#    CONFIG.PSU_MIO_27_SLEW {fast} \
# #TE_MOD#    CONFIG.PSU_MIO_27_POLARITY {Default} \
# #TE_MOD#    CONFIG.PSU_MIO_27_DRIVE_STRENGTH {12} \
# #TE_MOD#    CONFIG.PSU_MIO_27_DIRECTION {in} \
# #TE_MOD#    CONFIG.PSU_MIO_26_SLEW {fast} \
# #TE_MOD#    CONFIG.PSU_MIO_26_POLARITY {Default} \
# #TE_MOD#    CONFIG.PSU_MIO_26_DRIVE_STRENGTH {12} \
# #TE_MOD#    CONFIG.PSU_MIO_26_DIRECTION {in} \
# #TE_MOD#    CONFIG.PSU_MIO_25_POLARITY {Default} \
# #TE_MOD#    CONFIG.PSU_MIO_25_DIRECTION {inout} \
# #TE_MOD#    CONFIG.PSU_MIO_24_POLARITY {Default} \
# #TE_MOD#    CONFIG.PSU_MIO_24_DIRECTION {inout} \
# #TE_MOD#    CONFIG.PSU_MIO_23_POLARITY {Default} \
# #TE_MOD#    CONFIG.PSU_MIO_23_INPUT_TYPE {cmos} \
# #TE_MOD#    CONFIG.PSU_MIO_23_DIRECTION {out} \
# #TE_MOD#    CONFIG.PSU_MIO_22_POLARITY {Default} \
# #TE_MOD#    CONFIG.PSU_MIO_22_INPUT_TYPE {cmos} \
# #TE_MOD#    CONFIG.PSU_MIO_22_DIRECTION {out} \
# #TE_MOD#    CONFIG.PSU_MIO_21_POLARITY {Default} \
# #TE_MOD#    CONFIG.PSU_MIO_21_DIRECTION {inout} \
# #TE_MOD#    CONFIG.PSU_MIO_20_POLARITY {Default} \
# #TE_MOD#    CONFIG.PSU_MIO_20_DIRECTION {inout} \
# #TE_MOD#    CONFIG.PSU_MIO_1_POLARITY {Default} \
# #TE_MOD#    CONFIG.PSU_MIO_1_DIRECTION {inout} \
# #TE_MOD#    CONFIG.PSU_MIO_19_POLARITY {Default} \
# #TE_MOD#    CONFIG.PSU_MIO_19_DIRECTION {inout} \
# #TE_MOD#    CONFIG.PSU_MIO_18_POLARITY {Default} \
# #TE_MOD#    CONFIG.PSU_MIO_18_DIRECTION {inout} \
# #TE_MOD#    CONFIG.PSU_MIO_17_POLARITY {Default} \
# #TE_MOD#    CONFIG.PSU_MIO_17_DIRECTION {inout} \
# #TE_MOD#    CONFIG.PSU_MIO_16_POLARITY {Default} \
# #TE_MOD#    CONFIG.PSU_MIO_16_DIRECTION {inout} \
# #TE_MOD#    CONFIG.PSU_MIO_15_POLARITY {Default} \
# #TE_MOD#    CONFIG.PSU_MIO_15_DIRECTION {inout} \
# #TE_MOD#    CONFIG.PSU_MIO_14_POLARITY {Default} \
# #TE_MOD#    CONFIG.PSU_MIO_14_DIRECTION {inout} \
# #TE_MOD#    CONFIG.PSU_MIO_13_POLARITY {Default} \
# #TE_MOD#    CONFIG.PSU_MIO_13_DIRECTION {inout} \
# #TE_MOD#    CONFIG.PSU_MIO_12_POLARITY {Default} \
# #TE_MOD#    CONFIG.PSU_MIO_12_INPUT_TYPE {cmos} \
# #TE_MOD#    CONFIG.PSU_MIO_12_DIRECTION {out} \
# #TE_MOD#    CONFIG.PSU_MIO_11_POLARITY {Default} \
# #TE_MOD#    CONFIG.PSU_MIO_11_DIRECTION {inout} \
# #TE_MOD#    CONFIG.PSU_MIO_10_POLARITY {Default} \
# #TE_MOD#    CONFIG.PSU_MIO_10_DIRECTION {inout} \
# #TE_MOD#    CONFIG.PSU_MIO_0_POLARITY {Default} \
# #TE_MOD#    CONFIG.PSU_MIO_0_INPUT_TYPE {cmos} \
# #TE_MOD#    CONFIG.PSU_MIO_0_DIRECTION {out} \
# #TE_MOD#    CONFIG.PSU_DDR_RAM_LOWADDR_OFFSET {0x80000000} \
# #TE_MOD#    CONFIG.PSU_DDR_RAM_HIGHADDR_OFFSET {0x800000000} \
# #TE_MOD#    CONFIG.PSU_DDR_RAM_HIGHADDR {0xFFFFFFFF} \
# #TE_MOD#    CONFIG.PSU_BANK_3_IO_STANDARD {LVCMOS18} \
# #TE_MOD#    CONFIG.PSU_BANK_2_IO_STANDARD {LVCMOS18} \
# #TE_MOD#    CONFIG.PSU_BANK_1_IO_STANDARD {LVCMOS18} \
# #TE_MOD#    CONFIG.PSU_BANK_0_IO_STANDARD {LVCMOS18} \
# #TE_MOD# #Empty Line
  # Create interface connections
  connect_bd_intf_net -intf_net I2S_0_1 [get_bd_intf_ports I2S] [get_bd_intf_pins axis_live_audio_0/I2S]
  connect_bd_intf_net -intf_net RGPIO_Master_CPLD_RGPIO_M_EXT [get_bd_intf_pins RGPIO/RGPIO_M_EXT] [get_bd_intf_pins SC0808BF_0/RGPIO_MASTER_CPLD]
  connect_bd_intf_net -intf_net RGPIO_Slave_CPLD_RGPIO_M_EXT [get_bd_intf_pins RGPIO/RGPIO_M_EXT1] [get_bd_intf_pins SC0808BF_0/RGPIO_SLAVE_CPLD]
  connect_bd_intf_net -intf_net SC0808BF_0_BASE [get_bd_intf_ports BASE] [get_bd_intf_pins SC0808BF_0/BASE]
  connect_bd_intf_net -intf_net axis_live_audio_0_m_axis [get_bd_intf_pins axis_live_audio_0/m_axis] [get_bd_intf_pins zynq_ultra_ps_e_0/S_AXIS_AUDIO]
  connect_bd_intf_net -intf_net zynq_ultra_ps_e_0_CAN_0 [get_bd_intf_pins SC0808BF_0/CAN] [get_bd_intf_pins zynq_ultra_ps_e_0/CAN_0]
  connect_bd_intf_net -intf_net zynq_ultra_ps_e_0_M_AXIS_MIXED_AUDIO [get_bd_intf_pins axis_live_audio_0/s_axis] [get_bd_intf_pins zynq_ultra_ps_e_0/M_AXIS_MIXED_AUDIO]

  # Create port connections
  connect_bd_net -net SC0808BF_0_PS_AUX_DI [get_bd_pins SC0808BF_0/PS_AUX_DI] [get_bd_pins zynq_ultra_ps_e_0/dp_aux_data_in]
  connect_bd_net -net SC0808BF_0_PS_DP_HPD [get_bd_pins SC0808BF_0/PS_DP_HPD] [get_bd_pins zynq_ultra_ps_e_0/dp_hot_plug_detect]
  connect_bd_net -net proc_sys_reset_0_peripheral_aresetn [get_bd_pins RGPIO/RGPIO_M_RESET_N] [get_bd_pins proc_sys_reset_0/peripheral_aresetn]
  connect_bd_net -net vio_CAN_0_S [get_bd_pins SC0808BF_0/CAN_S] [get_bd_pins vio_general/probe_out2]
  connect_bd_net -net vio_LED_HD [get_bd_pins SC0808BF_0/LED_HD] [get_bd_pins vio_general/probe_out0]
  connect_bd_net -net vio_LED_XMOD2 [get_bd_pins SC0808BF_0/LED_XMOD2] [get_bd_pins vio_general/probe_out1]
  connect_bd_net -net zynq_ultra_ps_e_0_dp_audio_ref_clk [get_bd_pins axis_live_audio_0/axis_aclk] [get_bd_pins zynq_ultra_ps_e_0/dp_audio_ref_clk] [get_bd_pins zynq_ultra_ps_e_0/dp_s_axis_audio_clk]
  connect_bd_net -net zynq_ultra_ps_e_0_dp_aux_data_oe_n [get_bd_pins SC0808BF_0/PS_AUX_OE] [get_bd_pins zynq_ultra_ps_e_0/dp_aux_data_oe_n]
  connect_bd_net -net zynq_ultra_ps_e_0_dp_aux_data_out [get_bd_pins SC0808BF_0/PS_AUX_DO] [get_bd_pins zynq_ultra_ps_e_0/dp_aux_data_out]
  connect_bd_net -net zynq_ultra_ps_e_0_pl_clk0 [get_bd_pins RGPIO/clk] [get_bd_pins proc_sys_reset_0/slowest_sync_clk] [get_bd_pins zynq_ultra_ps_e_0/pl_clk1]
  connect_bd_net -net zynq_ultra_ps_e_0_pl_clk1 [get_bd_pins RGPIO/clk1] [get_bd_pins vio_general/clk] [get_bd_pins zynq_ultra_ps_e_0/maxihpm0_lpd_aclk] [get_bd_pins zynq_ultra_ps_e_0/pl_clk0]
  connect_bd_net -net zynq_ultra_ps_e_0_pl_resetn0 [get_bd_pins proc_sys_reset_0/ext_reset_in] [get_bd_pins zynq_ultra_ps_e_0/pl_resetn0]

  # Create address segments


  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""



