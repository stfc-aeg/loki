# --------------------------------------------------------------------
# --   *****************************
# --   *   Trenz Electronic GmbH   *
# --   *   Holzweg 19A             *
# --   *   32257 Bünde             *
# --   *   Germany                 *
# --   *****************************
# --------------------------------------------------------------------
# -- $Author: Hartfiel, John $
# -- $Email: j.hartfiel@trenz-electronic.de $
# --------------------------------------------------------------------
# -- Change History:
# ------------------------------------------
# -- $Date: 2019/12/11 | $Author: Hartfiel, John
# -- - add Zynq support
# ------------------------------------------
# -- $Date: 2019/12/01 | $Author: Hartfiel, John
# -- - initial release with zynqMP support
# ------------------------------------------
# -- $Date: 2019/12/06 | $Author: Hartfiel, John
# -- - zynq support
# ------------------------------------------
# -- $Date: 2019/12/16 | $Author: Hartfiel, John
# -- - microblaze support, bugfixes, multiple domains on platfrom csv
# ------------------------------------------
# -- $Date: 2020/01/14 | $Author: Hartfiel, John
# -- - add possibility of linux domain and  copy files from prebuilts to the workspace (currently more beta)
# ------------------------------------------
# -- $Date: 0000/00/00  | $Author:
# -- - 
# --------------------------------------------------------------------
# --------------------------------------------------------------------
namespace eval ::TE {
  namespace eval VITIS {
    set SW_APPLIST ""
    set SCRIPT_PATH ../../scripts
    set LIB_PATH ../../sw_lib
    set ID UNKOWN
    set SERIESNAME UNKOWN
    set WORKSPACE_SDK_PATH ../../workspace/sdk
    #will be set with platform_create
    set SYSTEM zynqMP
    # set SYSTEM zynq
    # set SYSTEM microblaze
    # -----------------------------------------------------------------------------------------------------------------------------------------
    # TE HSI variablen declaration
    # -----------------------------------------------------------------------------------------------------------------------------------------
    # -----------------------------------------------------------------------------------------------------------------------------------------
    # finished TE HSI variablen declaration
    # -----------------------------------------------------------------------------------------------------------------------------------------
    # -----------------------------------------------------------------------------------------------------------------------------------------
    # hsi hw functions
    # -----------------------------------------------------------------------------------------------------------------------------------------
    proc create_linux_source { domainname } { 
      set linux_path [TE::UTILS::prebuilt_file_location true  * *.ub petalinux NA $TE::WORKSPACE_SDK_PATH true]
      if {![string match "NA" $linux_path]} {
        set basepath ${TE::WORKSPACE_SDK_PATH}/${TE::PRODID}/resources
        # set basepath ${TE::WORKSPACE_SDK_PATH}/petalinux_resources
        file mkdir ${basepath}
        set bif_loc  ${basepath}/bif
        set boot_loc  ${basepath}/boot
        set linux_loc  ${basepath}/sd
        file mkdir  ${bif_loc}
        file mkdir  ${boot_loc}
        file mkdir  ${linux_loc}
        
        set linux_files [glob -nocomplain -join -dir ${linux_path} *]
        foreach file $linux_files {
          if {![string match *.elf $file]} { 
            #linux image.ub or other files
            file copy -force ${file} ${linux_loc} 
          } else {
            #elf files like uboot, atf and pmu 
            file copy -force ${file} ${boot_loc} 
          }
        }
        set add_files [glob -nocomplain -join -dir ${TE::ADD_SD_PATH} *]
        foreach file $add_files {
          file copy -force ${file} ${linux_loc} 
        }
        #.bit normally not needed because it's used from the xsa
        set tmp_bitstream [TE::UTILS::prebuilt_file_location true * .bit NA NA NA false]
        if {[file exists $tmp_bitstream ]} {
          file copy -force ${tmp_bitstream} ${boot_loc} 
        }
        #maybe check also applist and add files to bif, if set(works only for one style) 
        if {$TE::VITIS::SYSTEM eq "zynq"} {
          set tmp_fsbl [TE::UTILS::prebuilt_file_location true  fsbl .elf NA NA $TE::WORKSPACE_SDK_PATH false]
          if {[file exists $tmp_fsbl ]} {
            file copy -force ${tmp_fsbl} ${boot_loc} 
            set bif_fsbl "<fsbl.elf>"
          } else {
            set bif_fsbl "${TE::WORKSPACE_SDK_PATH}/${TE::PRODID}/export/${TE::PRODID}/sw/${TE::PRODID}/boot/fsbl.elf"
          }
          TE::UTILS::vitis_z_bif -biffile ${bif_loc}/boot.bif -linux true -bootloader $bif_fsbl

        } elseif {$TE::VITIS::SYSTEM eq "zynqMP"} {
          set tmp_fsbl [TE::UTILS::prebuilt_file_location true  fsbl .elf NA NA $TE::WORKSPACE_SDK_PATH false]
          set tmp_pmu [TE::UTILS::prebuilt_file_location true  pmufw .elf NA NA $TE::WORKSPACE_SDK_PATH false]
          
          if {[file exists $tmp_fsbl ]} {
            file copy -force ${tmp_fsbl} ${boot_loc} 
            set bif_fsbl "<fsbl.elf>"
          } else {
            set bif_fsbl "${TE::WORKSPACE_SDK_PATH}/${TE::PRODID}/export/${TE::PRODID}/sw/${TE::PRODID}/boot/fsbl.elf"
          }
          if {[file exists $tmp_pmu ]} {
            file copy -force ${tmp_pmu} ${boot_loc} 
            set bif_pmu "<pmufw.elf>"
          } else {
            set bif_pmu "${TE::WORKSPACE_SDK_PATH}/${TE::PRODID}/export/${TE::PRODID}/sw/${TE::PRODID}/boot/pmufw.elf"
          }
          TE::UTILS::vitis_zmp_bif -biffile ${bif_loc}/boot.bif -linux true -bootloader $bif_fsbl -pmu $bif_pmu
        } elseif {$TE::VITIS::SYSTEM eq "microblaze"} {
          #todo
        } else {
          puts "Error:(TE) linux file ${TE::PRODID} failed: unknown system type $TE::VITIS::SYSTEM"
        }
        domain active ${domainname}
        domain config -boot ${boot_loc}
        platform write
        domain config -bif ${bif_loc}/boot.bif
        platform write
        domain config -image ${linux_loc}
        platform write
        domain -report -json
        domain config -runtime {cpp}
        platform write
      }
    }
    
    
    proc set_workspace {} { 
      setws ${TE::WORKSPACE_SDK_PATH}
      repo -set ${TE::LIB_PATH}
      repo -scan
    }
    proc check_system_type {{name NA}} {
      if {[string match "NA" $name]} {
        foreach sw_platlist_line $TE::SDEF::SW_PLATLIST {
          if { [lindex $sw_platlist_line ${TE::SDEF::P_ID}] ne "id" } {
            set p_proc [lindex $sw_platlist_line ${TE::SDEF::P_PROC}]
            #todo list of possible systems
            if {[string match "a9*" $p_proc]} {
              set TE::VITIS::SYSTEM zynq  
            } elseif {[string match "a53*" $p_proc]} {
              set TE::VITIS::SYSTEM zynqMP  
            } elseif {[string match "microblaze*" $p_proc]} {
              set TE::VITIS::SYSTEM microblaze  
            } else {
               puts "Error:(TE) platform ${TE::PRODID}  (TE::VITIVS::check_system_type check):system type failed: unknown processor type $p_proc"
            }
          }
        }
      } else {
        set TE::VITIS::SYSTEM $name  
      }
    
    }
    proc platform_create {} {    
      #create platform project
     
      foreach sw_platlist_line $TE::SDEF::SW_PLATLIST {
        # if { [lindex $sw_platlist_line ${TE::SDEF::P_ID}] ne "id" } {}
        #generate platfrom only one time, use domains to generate addional domains
        if { [lindex $sw_platlist_line ${TE::SDEF::P_ID}] eq "0" } {
          set p_os [lindex $sw_platlist_line ${TE::SDEF::P_OS}]
          set p_proc [lindex $sw_platlist_line ${TE::SDEF::P_PROC}]
          
          if {[string match "a9-*" $p_proc]} { 
            set p_proc "ps7_cortex[string map {"-" "_"} $p_proc]"
          } elseif {[string match "a53-*" $p_proc]} {
            set p_proc "psu_cortex[string map {"-" "_"} $p_proc]"
          } else {
             #use as it is --> for microblaze for example 
          }
          if {[catch {
            if {[catch {set xsafiles [glob -join -dir ${TE::WORKSPACE_SDK_PATH} *.xsa]} ]} {
              puts "Error:(TE) platform ${TE::PRODID} failed: .xsa does not exist in ${TE::WORKSPACE_SDK_PATH}."
            }
            set xsafile [lindex $xsafiles 0]
            
            platform create -name ${TE::PRODID} -hw ${xsafile} -proc $p_proc -os $p_os -out ${TE::WORKSPACE_SDK_PATH}
            platform write
            platform read ${TE::WORKSPACE_SDK_PATH}/${TE::PRODID}/platform.spr


          } result]} { puts "Error:(TE) platform ${TE::PRODID} failed: $result."}
        }
      }
    }

    proc platform_domains {} {
      if {[catch {
        #predefined for zynqMP
        # --> add or remove:  todo 
        # platform config -remove-boot-bsp
        # platform write
        # platform config -create-boot-bsp
        if {[catch {set xsafiles [glob -join -dir ${TE::WORKSPACE_SDK_PATH}/${TE::PRODID}/hw/ *.xsa]} ]} {
          puts "Error:(TE) platform ${TE::PRODID} failed: .xsa does not exist in ${TE::WORKSPACE_SDK_PATH}/${TE::PRODID}/hw/."
        }
        set xsafile [lindex $xsafiles 0]
        
        
        platform active ${TE::PRODID}
        
        if {$TE::VITIS::SYSTEM eq "zynq"} {
          domain active {zynq_fsbl}
          ::scw::get_hw_path
          ::scw::regenerate_psinit ${xsafile}
          ::scw::get_mss_path
          domain active {standalone_domain}
          ::scw::get_hw_path
          ::scw::regenerate_psinit ${xsafile}
          ::scw::get_mss_path
        } elseif {$TE::VITIS::SYSTEM eq "zynqMP"} {
          domain active {zynqmp_fsbl}
          ::scw::get_hw_path
          ::scw::regenerate_psinit ${xsafile}
          ::scw::get_mss_path
          domain active {zynqmp_pmufw}
          ::scw::get_hw_path
          ::scw::regenerate_psinit ${xsafile}
          ::scw::get_mss_path
          domain active {standalone_domain}
          ::scw::get_hw_path
          ::scw::regenerate_psinit ${xsafile}
          ::scw::get_mss_path
        } elseif {$TE::VITIS::SYSTEM eq "microblaze"} {
          domain active {standalone_domain}
          ::scw::get_hw_path
          ::scw::regenerate_psinit ${xsafile}
          ::scw::get_mss_path
        } else {
          puts "Error:(TE) platform ${TE::PRODID} failed: unknown system type $TE::VITIS::SYSTEM"
        }
        foreach sw_platlist_line $TE::SDEF::SW_PLATLIST {
          if { [lindex $sw_platlist_line ${TE::SDEF::P_NAME}] ne "NA" && [lindex $sw_platlist_line ${TE::SDEF::P_ID}] ne "id"} {
            set p_name [lindex $sw_platlist_line ${TE::SDEF::P_NAME}]
            set p_os [lindex $sw_platlist_line ${TE::SDEF::P_OS}]
            set p_proc [lindex $sw_platlist_line ${TE::SDEF::P_PROC}]
            
            if {[string match "a9-*" $p_proc]} { 
              set p_proc "ps7_cortex[string map {"-" "_"} $p_proc]"
            } elseif {[string match "a9" $p_proc]} {
              set p_proc "ps7_cortex${p_proc}"
            } elseif {[string match "a53-*" $p_proc]} {
              set p_proc "psu_cortex[string map {"-" "_"} $p_proc]"
            } elseif {[string match "a53" $p_proc]} {
              set p_proc "psu_cortex${p_proc}"
            } else {
               #use as it is --> for microblaze for example 
            }
            if {[catch {
              if {[catch {set xsafiles [glob -join -dir ${TE::WORKSPACE_SDK_PATH} *.xsa]} ]} {
                puts "Error:(TE) platform ${TE::PRODID} failed: .xsa does not exist in ${TE::WORKSPACE_SDK_PATH}."
              }
              set xsafile [lindex $xsafiles 0]
              
              set d_name "${p_name}_${p_os}_domain"
              set dp_name "${p_os} on ${p_proc}"
              set dpd_name "${p_name} ${p_os} on ${p_proc}"
              domain create -name $d_name -os $p_os -proc $p_proc -display-name $dp_name -desc $d_name -runtime {cpp}
              platform write
              if {[string match "linux" $p_os]} {
                #todo: test only
                TE::VITIS::create_linux_source $d_name
                #set standalone as active
                domain active {standalone_domain}
              } else {
                ::scw::get_hw_path
                ::scw::regenerate_psinit ${xsafile}
                ::scw::get_mss_path
              }
              

            } result]} { puts "Error:(TE) platform ${TE::PRODID} failed: $result."}
          }
        }
        
      } result]} { puts "Error:(TE) platform ${TE::PRODID} failed: $result."}
    }
    
    proc get_domain_name {proc_name} {
      set d_name "NA"
      foreach sw_platlist_line $TE::SDEF::SW_PLATLIST {
        set p_name [lindex $sw_platlist_line ${TE::SDEF::P_NAME}]
        set p_os [lindex $sw_platlist_line ${TE::SDEF::P_OS}]
        set p_proc [lindex $sw_platlist_line ${TE::SDEF::P_PROC}]

        if { $p_proc eq "$proc_name"} {
          if { $p_name ne "NA"} {
            set d_name "${p_name}_${p_os}_domain"
          } else {
            set d_name "${p_os}_domain"
          }
        }
      }
      return $d_name
    }
    
    proc bsp_modify {} {
      foreach sw_bsplist_line $TE::SDEF::SW_BSPLIST {
        if { [lindex $sw_bsplist_line ${TE::SDEF::B_ID}] ne "id" } {
          if {[catch {
            set b_name [lindex $sw_bsplist_line ${TE::SDEF::B_NAME}]
            set b_os [lindex $sw_bsplist_line ${TE::SDEF::B_OS}]
            set d_name "NA"
            if { $b_name ne "NA" } { 
              set d_name "${b_name}_${b_os}_domain"
            } else {
              set d_name "${b_os}_domain"
            }
            # puts "Test:$d_name"
            platform active ${TE::PRODID}
            domain active $d_name
            
            if { [lindex $sw_bsplist_line ${TE::SDEF::B_UART}] ne "NA" } { 
              bsp config stdin [lindex $sw_bsplist_line ${TE::SDEF::B_UART}]
              bsp config stdout [lindex $sw_bsplist_line ${TE::SDEF::B_UART}]
            }
            if { [lindex $sw_bsplist_line ${TE::SDEF::B_LIBS}] ne "NA" } { 
              set tmp [split [lindex $sw_bsplist_line ${TE::SDEF::B_LIBS}] ","]
              foreach xlib $tmp {
                bsp setlib $xlib
              }
            }          
            bsp regenerate
          } result]} { puts "Error:(TE) BSP [lindex $sw_bsplist_line ${TE::SDEF::B_NAME}]  failed: $result."}
        }
      }
    }
    
    proc platform_generate {} {
       #use this to add platform to SDK directly --> it will not opened on but platfrom generation step can be skipped --> directly add app
       platform generate
       
       importprojects ${TE::WORKSPACE_SDK_PATH}/${TE::PRODID}
    }
    
    proc app_create {} {
      
      foreach sw_applist_line $TE::SDEF::SW_APPLIST {
        if { [lindex $sw_applist_line ${TE::SDEF::ID}] ne "id" } {
           
          if { [lindex $sw_applist_line ${TE::SDEF::STEPS}] eq "0" || [lindex $sw_applist_line ${TE::SDEF::STEPS}] eq "3"} {
            set app_name [lindex $sw_applist_line ${TE::SDEF::APPNAME}]
            set app_template [lindex $sw_applist_line ${TE::SDEF::TEMPLATE_NAME}]
            set app_os [lindex $sw_applist_line ${TE::SDEF::OSNAME}]
            if {[catch {        
              platform active ${TE::PRODID}
              set app_proc [lindex $sw_applist_line ${TE::SDEF::DESTINATION_CPU}]
              set  domainname [get_domain_name $app_proc]
              if { $domainname eq "NA" } {
                set domainname  "${app_os}_domain"
              }
              domain active $domainname
              if {[string match "a9-*" $app_proc]} { 
                set app_proc "ps7_cortex[string map {"-" "_"} $app_proc]"
              } elseif {[string match "a53-*" $app_proc]} {
                set app_proc "psu_cortex[string map {"-" "_"} $app_proc]"
              } else {
                 #use as it is --> for microblaze for example 
              }
            puts "Test |${app_name}|${TE::PRODID}|${app_proc}|${app_os}|${app_template}|| "
              app create -name  ${app_name} -platform ${TE::PRODID} -proc ${app_proc} -os ${app_os} -template ${app_template}
              
              if { [lindex $sw_applist_line ${TE::SDEF::CSYMB}] ne "NA" } { 
                set tmp [split [lindex $sw_applist_line ${TE::SDEF::CSYMB}] ","]
                foreach symb $tmp {
                  app config -name ${app_name} define-compiler-symbols $symb 
                }
              }               
              if { [lindex $sw_applist_line ${TE::SDEF::BUILD}] ne "NA" } { 
                app config -name  ${app_name} build-config [lindex $sw_applist_line ${TE::SDEF::BUILD}]
              } 
            } result]} { puts "Error:(TE) create  $app_name failed: $result."}
        
          }
        }
      
      }
    }    
    proc app_build {{name *}} {
      set tmplist [app list]
      set index 0
      foreach element $tmplist {
        if {$index>2} {
          if {[string match $name $element]} {
          
            if {[catch {
              app build $element
            } result]} { puts "Error:(TE) build $element failed: $result."}

            puts "build $element "
          } else {
            puts "skip $element"
          }
        } else {
          puts "$element"
        }
        incr index
      }
    }
    
    proc app_delete {{name *}} {
      set tmplist [app list]
      set index 0
      foreach element $tmplist {
        if {$index>2} {
          if {[string match $name $element]} {
            app remove $element
            puts "remove $element "
          } else {
            puts "skip $element"
          }
        } else {
          puts "$element"
        }
        incr index
      }
    }   
    proc app_clean {{name *}} {
      set tmplist [app list]
      set index 0
      foreach element $tmplist {
        if {$index>2} {
          if {[string match $name $element]} {
            app clean $element
            puts "clean -name $element "
          } else {
            puts "skip $element"
          }
        } else {
          puts "$element"
        }
        incr index
      }
    }
    
    proc open_workspace_gui {} { 
        set tmplist [list]

        lappend tmplist "-lp" ${TE::LIB_PATH}
        set command exec
        lappend command vitis
        lappend command -workspace ${TE::WORKSPACE_SDK_PATH}
        lappend command {*}$tmplist
        if { [catch {eval $command} result ]  } {
          puts "Error:(TE) ScriptCommand results from vitis \"$command\": $result \n"
        } else {
          puts "INFO:(TE) ScriptCommand results from vitis \"$command\": $result \n"
        }
    }
    #--------------------------------
    #--run_all:
    proc ex_rescan {} { 
      #this is a workaround -->  platform create failes with xsct started manually but works with vivado and scripts directly.
       puts "Info:(TE) Set  system type..."
      if {[catch {TE::VITIS::check_system_type} result]} { puts "Error:(TE) Script (TE::VITIS::check_system_type) failed: $result."}
       puts "Info:(TE) Create workspace..."
      if {[catch {TE::VITIS::set_workspace} result]} { puts "Error:(TE) Script (TE::VITIS::set_workspace) failed: $result."}
      puts "Info:(TE) Read platform..."
      platform read ${TE::WORKSPACE_SDK_PATH}/${TE::PRODID}/platform.spr
      platform active ${TE::PRODID}
      
    }
    
    
    
   #--------------------------------
    #--run_all:
    proc run_all {} {
      puts "Info:(TE) VITIS...run all..."
       puts "Info:(TE) Set  system type..."
      if {[catch {TE::VITIS::check_system_type} result]} { puts "Error:(TE) Script (TE::VITIS::check_system_type) failed: $result."}
       puts "Info:(TE) Create workspace..."
      if {[catch {TE::VITIS::set_workspace} result]} { puts "Error:(TE) Script (TE::VITIS::set_workspace) failed: $result."}
       puts "Info:(TE) Create platform..."
      if {[catch {TE::VITIS::platform_create} result]} { puts "Error:(TE) Script (TE::VITIS::platform_create) failed: $result."}
      after  1000
       puts "Info:(TE) Create platform domains..."
      if {[catch {TE::VITIS::platform_domains} result]} { puts "Error:(TE) Script (TE::VITIS::platform_domains) failed: $result."}
      after  1000
       puts "Info:(TE) Modify BSP..."
      if {[catch {TE::VITIS::bsp_modify} result]} { puts "Error:(TE) Script (TE::VITIS::bsp_modify) failed: $result."}
      after  1000
       puts "Info:(TE) Generate platform..."
      if {[catch {TE::VITIS::platform_generate} result]} { puts "Error:(TE) Script (TE::VITIS::platform_generate) failed: $result."}
      after  1000
       puts "Info:(TE) Create Apps..."
      if {[catch {TE::VITIS::app_create} result]} { puts "Error:(TE) Script (TE::VITIS::app_create) failed: $result."}
       puts "Info:(TE) Clean Apps..."
      if {[catch {TE::VITIS::app_clean} result]} { puts "Error:(TE) Script (TE::VITIS::app_clean) failed: $result."}
       puts "Info:(TE) Build Apps..."
      if {[catch {TE::VITIS::app_build} result]} { puts "Error:(TE) Script (TE::VITIS::app_build) failed: $result."}
      puts "Info:(TE) finished..."
      #--> done via vivado otherwise it can be happens some conflict with file lock of previous tasks
      # if {[catch {open_workspace_gui} result]} { puts "Error:(TE) Script (TE::VITIS::open_workspace_gui) failed: $result."}
    }
    
    #--------------------------------
    #--return_option: 
    proc help {} {
      puts "source ../../scripts/script_vitis.tcl   --> rescan scripts and configs "
      puts "TE::VITIS::ex_rescan                    --> rescan platform "
      puts "TE::VITIS::platform_domains             --> create domains(some are predefined)"
      puts "TE::VITIS::bsp_modify                   --> modify bsp from csv"
      puts "TE::VITIS::platform_generate            --> generate platform"
      puts "TE::VITIS::app_create                   --> create apps from csv"
      puts "TE::VITIS::app_clean <arg>              --> clean  all apps or optional defined app"
      puts "TE::VITIS::app_build <arg>              --> build  all apps or optional defined app"
      puts "TE::VITIS::app_delete  <arg>            --> delete  all apps or optional defined app"
      puts "TE::VITIS::open_workspace_gui           --> open Vitis"
      puts "--------"
      puts "repo -apps                              --> show available app templates"
    }
    
    #--------------------------------
    #--return_option: 
    proc return_option {option argc argv} {
      if { $argc <= [expr $option + 1]} { 
        return -code error "Error:(TE) Read parameter failed"
      } else {  
        puts "Info:(TE) Parameter Option Value: [lindex $argv [expr $option + 1]]"
        return [lindex $argv [expr $option + 1]]
      }
    }  
    #--------------------------------
    #--hsi_main: 
    proc vitis_main {} {
      global argc
      global argv
      set tmp_argc 0
      set tmp_argv 0
      if {$argc >= 1 } {
        set tmp_argv [lindex $argv 0]
        set tmp_argc [llength $tmp_argv]
      }
      
      set tmp_argv [split $tmp_argv "*"]
      set tmp_argc [llength $tmp_argv]
      
      set vivrun false
      set platform_only false
      set worspace_only false
      set id_tmp "UNKOWN"
     
      
      for {set option 0} {$option < $tmp_argc} {incr option} {
        puts "Info:(TE) Parameter Index: $option"
        puts "Info:(TE) Parameter Option: [lindex $tmp_argv $option]"
        switch [lindex $tmp_argv $option] {
          "--id"	            { set id_tmp [return_option $option $tmp_argc $tmp_argv];incr option;  }       
          "--platform_only"		    { set platform_only true }
          "--worspace_only"		    { set worspace_only true }
          "--vivrun"		      { set vivrun true }
          default             { puts "" }
        }
      }
       source ${TE::VITIS::SCRIPT_PATH}/script_te_utils.tcl
       source ${TE::VITIS::SCRIPT_PATH}/script_external.tcl
       source ${TE::VITIS::SCRIPT_PATH}/script_settings.tcl
       set tmppath [pwd]
       cd ../../
       if {[catch {TE::INIT::init_pathvar} result]} {  puts "Error:(TE) Script Initialization...$result";  return -code error}
       cd $tmppath
      if {[catch {TE::INIT::init_boardlist} result]} {  puts "Error:(TE) Script Initialization...$result";return -code error}
      if {[catch {TE::INIT::init_app_list} result]} { puts "Error:(TE) Script Initialization...$result"; return -code error} 
      
      # todo add option to recover product id from platform project
       set prod_id [TE::UTILS::read_board_select] 
       if { $id_tmp ne "UNKOWN" } {
         TE::INIT::init_board  [TE::BDEF::find_id $id_tmp] $TE::BDEF::ID
       } elseif {![string match "NA" $prod_id] == 1} {
         TE::INIT::init_board $prod_id $TE::BDEF::PRODID
       } else {
         puts "INFO:(TE) Script (TE::VITIS::vitis_main) use part name from environment with PARTNUMBER=$::env(PARTNUMBER)."
         TE::INIT::init_board  [TE::BDEF::find_id $::env(PARTNUMBER)] $TE::BDEF::ID
       }
      
      puts "INFO: (TE): ${TE::WORKSPACE_SDK_PATH} is used as workspace"
      puts "INFO: (TE): See also UG1400-Vitis Embedded Software Development"
      TE::VITIS::check_system_type
      if {$vivrun==true} {
        
        if {$worspace_only==true} {
          # if {[catch {TE::UTILS::generate_workspace_sdk [TE::BDEF::find_id $id_tmp]} result]} { puts "Error:(TE) Script (TE::UTILS::generate_workspace_sdk) failed: $result." }
           puts "Info:(TE) Set  system type..."
          if {[catch {TE::VITIS::check_system_type} result]} { puts "Error:(TE) Script (TE::VITIS::check_system_type) failed: $result."}
           puts "Info:(TE) Create workspace..."
          if {[catch {TE::VITIS::set_workspace} result]} { puts "Error:(TE) Script (TE::VITIS::set_workspace) failed: $result."}
        } elseif {$platform_only==true} {
          # if {[catch {TE::UTILS::generate_workspace_sdk [TE::BDEF::find_id $id_tmp]} result]} { puts "Error:(TE) Script (TE::UTILS::generate_workspace_sdk) failed: $result." }
          
           puts "Info:(TE) Set  system type..."
          if {[catch {TE::VITIS::check_system_type} result]} { puts "Error:(TE) Script (TE::VITIS::check_system_type) failed: $result."}
           puts "Info:(TE) Create workspace..."
          if {[catch {TE::VITIS::set_workspace} result]} { puts "Error:(TE) Script (TE::VITIS::set_workspace) failed: $result."}
           puts "Info:(TE) Create platform..."
          if {[catch {TE::VITIS::platform_create} result]} { puts "Error:(TE) Script (TE::VITIS::platform_create) failed: $result."}
          after  1000
           puts "Info:(TE) Create platform domains..."
          if {[catch {TE::VITIS::platform_domains} result]} { puts "Error:(TE) Script (TE::VITIS::platform_domains) failed: $result."}
          after  1000
           puts "Info:(TE) Modify BSP..."
          if {[catch {TE::VITIS::bsp_modify} result]} { puts "Error:(TE) Script (TE::VITIS::bsp_modify) failed: $result."}
          after  1000
           puts "Info:(TE) Generate platform..."
          if {[catch {TE::VITIS::platform_generate} result]} { puts "Error:(TE) Script (TE::VITIS::platform_generate) failed: $result."}
         
        } else {
          if {[catch {run_all} result]} { puts "Error:(TE) Script (TE::VITIS::run_all) failed: $result."}
        }
        exit
      } else {
        TE::VITIS::help
      }

    }
    if {[catch {vitis_main} result]} {
      puts "Error:(TE) Script (TE::VITIS::vitis_main) failed: $result."
    } 
  
  # -----------------------------------------------------------------------------------------------------------------------------------------
  }
 puts "Info: Load VITIS scripts finished" 
 return ok
}
