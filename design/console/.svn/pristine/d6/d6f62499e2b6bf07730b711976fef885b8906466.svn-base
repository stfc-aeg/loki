@REM # --------------------------------------------------------------------
@REM # --   *****************************
@REM # --   *   Trenz Electronic GmbH   *
@REM # --   *   Holzweg 19A             *
@REM # --   *   32257 Bünde   		      *
@REM # --   *   Germany                 *
@REM # --   *****************************
@REM # --------------------------------------------------------------------
@REM # --$Autor: Hartfiel, John $
@REM # --$Email: j.hartfiel@trenz-electronic.de $
@REM # --$Create Date:2017/01/03 $
@REM # --$Modify Date: 2018/11/25 $
@REM # --$Version: 3.0 $
@REM # -- working in process
@REM # --$Version: 1.0 $
@REM # --------------------------------------------------------------------
@REM # --------------------------------------------------------------------
@REM set local environment
setlocal
@echo -- Error: Rework neccesarry, file currently not supported. --
@goto  ERROR


@echo ------------------------Set design paths----------------------------
@REM get paths
@set batchfile_name=%~n0
@set batchfile_drive=%~d0
@set batchfile_path=%~dp0
@REM change drive
@%batchfile_drive%
@REM change path to batchfile folder
@cd %batchfile_path%
@echo -- Run Design with: %batchfile_name%
@echo -- Use Design Path: %batchfile_path%
@set cmd_folder=%batchfile_path%console\base_cmd\

@REM ------------------------------------------------------------------------------
@REM :NEXT_TE_BASE
@REM @echo --------------------------------------------------------------------
@REM @echo -------------------------TE Reference Design---------------------------
@REM @echo --------------------------------------------------------------------
@REM @echo -- (d)  Go to Documentation (Web Documentation) TODO
@REM @echo -- (x)  Exit Batch (nothing is done!)
@REM @echo -- (0) Start Test...   
@REM @echo ----
@REM @set /p new_base=" Select (ex.:'0' start Test):"
@REM @if "%new_base%"=="d" (@GOTO NEXT_TE_DOC)
@REM @if "%new_base%"=="x" (@GOTO EOF)
@REM @if "%new_base%"=="0" (
@REM @set new_cmd=config
@REM @GOTO CONFIG_SETUP
@REM )
@REM @GOTO NEXT_TE_BASE
@REM @echo --------------------------------------------------------------------
@REM @REM ------------------------------------------------------------------------------
@REM :NEXT_TE_DOC
@REM @echo --------------------------------------------------------------------
@REM @echo -------------------------TE Documentation---------------------------
@REM @echo --------------------------------------------------------------------
@REM @echo -- (b)  Go to Base Menue
@REM @echo -- (x)  Exit Batch(nothing is done!)
@REM @echo -- (0)  TODO...
@REM @echo ----
@REM @set /p new_doc=" Select Document (ex.:'0' for Wiki ,'b' go to Base Menue):"
@REM @if "%new_doc%"=="b" (@GOTO NEXT_TE_BASE)
@REM @if "%new_doc%"=="x" (@GOTO EOF)
@REM @if "%new_doc%"=="0" (@start https://wiki.trenz-electronic.de/display/PD/Trenz+Electronic+Documentation)
@REM @GOTO NEXT_TE_DOC
@REM @echo --------------------------------------------------------------------
@REM @REM ------------------------------------------------------------------------------

:CONFIG_SETUP


@if not exist %batchfile_path%design_basic_settings.cmd ( @copy %cmd_folder%design_basic_settings.cmd %batchfile_path%design_basic_settings.cmd)
@if not exist %batchfile_path%_use_virtual_drive.cmd    ( @copy %cmd_folder%_use_virtual_drive.cmd %batchfile_path%_use_virtual_drive.cmd)

@REM # load environment and check vivado version
@call  %cmd_folder%design_basic_settings.cmd
@set DEF_VIVADO_VERSION=%VIVADO_VERSION%

@call design_basic_settings.cmd
@if  "%DEF_VIVADO_VERSION%" NEQ "%VIVADO_VERSION%" (
@echo -----------------------------------------
@echo Attantion:
@echo  - Design was created for Vivado %DEF_VIVADO_VERSION%, selected is Vivado %VIVADO_VERSION%
@echo  - Design only tested with Vivado %DEF_VIVADO_VERSION%, modifications needed for other versions
@echo .
@echo ... Continue with %VIVADO_VERSION% ...
)
@if not defined XILDIR (
  @set XILDIR=c:/xilinx
)
@echo -----------------------------------------
@REM # check Xilinx path
@set ckeckvivfolder=0
:XILINX_PATH
@if exist %XILDIR% (
  @echo Use Xilinx installation from '%XILDIR%\Vivado\%VIVADO_VERSION%\'
  @echo Use Xilinx installation from '%XILDIR%\SDK\%VIVADO_VERSION%\'
  @echo Use Xilinx installation from '%XILDIR%\Vivado_Lab\%VIVADO_VERSION%\'
)
@if not exist %XILDIR% (
  @echo '%XILDIR%' did not exists.
  @GOTO SPECIFY_XILINX_DIR
)

@set tmphit=0
@if exist %XILDIR%\Vivado\%VIVADO_VERSION%\ (
  @set tmphit=1
)
@if exist %XILDIR%\Vivado_Lab\%VIVADO_VERSION%\ (
  @set tmphit=1
)

@if %tmphit%==0 if %ckeckvivfolder%==0 (
  @echo '%XILDIR%\Vivado\%VIVADO_VERSION%\' did not exists.
  @echo '%XILDIR%\Vivado_Lab\%VIVADO_VERSION%\' did not exists.
  @GOTO SPECIFY_VIVADO_VERSION
)
@if %tmphit%==0 if %ckeckvivfolder%==1 (
  @echo '%XILDIR%\Vivado\%VIVADO_VERSION%\' did not exists.
  @echo '%XILDIR%\Vivado_Lab\%VIVADO_VERSION%\' did not exists.
  @GOTO SPECIFY_XILINX_DIR
)

:START_CONFIG
@REM # -----------------
@REM # --- copy bash files
@REM @if exist %cmd_folder%vivado_create_project_guimode.cmd ( @copy %cmd_folder%vivado_create_project_guimode.cmd %batchfile_path%vivado_create_project_guimode.cmd)
REM @if exist %cmd_folder%vivado_open_existing_project_guimode.cmd ( @copy %cmd_folder%vivado_open_existing_project_guimode.cmd %batchfile_path%vivado_open_existing_project_guimode.cmd)

@REM # -----------------
@REM # --- set environment
@echo ------------------Set Xilinx environment variables------------------
@set VIVADO_XSETTINGS=%XILDIR%\Vivado\%VIVADO_VERSION%\.settings64-Vivado.bat
@set SDK_XSETTINGS=%XILDIR%\SDK\%VIVADO_VERSION%\.settings64-SDK_Core_Tools.bat
@set LABTOOL_XSETTINGS=%XILDIR%\Vivado_Lab\%VIVADO_VERSION%\settings64.bat
@if not defined ENABLE_SDSOC (
  @set ENABLE_SDSOC=0
)
@if %ENABLE_SDSOC%==1 (
  @echo --Info: SDSOC use Vivado and SDK from SDx installation --
  @set SDSOC_XSETTINGS=%XILDIR%\SDx\%VIVADO_VERSION%\settings64.bat
  @set VIVADO_XSETTINGS=%XILDIR%\Vivado\%VIVADO_VERSION%\settings64.bat
  @set SDK_XSETTINGS=%XILDIR%\SDK\%VIVADO_VERSION%\settings64.bat
)

@REM # --------------------
@if not defined VIVADO_AVAILABLE (
  @set VIVADO_AVAILABLE=0
)
@if not defined SDK_AVAILABLE (
  @set SDK_AVAILABLE=0
)
@if not defined LABTOOL_AVAILABLE (
  @set LABTOOL_AVAILABLE=0
)
@if not defined SDSOC_AVAILABLE (
  @set SDSOC_AVAILABLE=0
)

@REM # --------------------
@echo -- Use Xilinx Version: %VIVADO_VERSION% --
@echo -----------------------------------------
@if not defined VIVADO_XSETTINGS_ISDONE ( @echo -- Info: Configure Xilinx Vivado Settings --
  @if not exist %VIVADO_XSETTINGS% ( @echo --     Critical Warning: %VIVADO_XSETTINGS% not found --
  ) else (
    @call %VIVADO_XSETTINGS%
    @set VIVADO_AVAILABLE=1
  )
  @set VIVADO_XSETTINGS_ISDONE=1
)
@if not defined SDK_XSETTINGS_ISDONE ( @echo -- Info: Configure Xilinx SDK Settings --
  @if not exist %SDK_XSETTINGS% ( @echo --     Critical Warning: %SDK_XSETTINGS% not found --
  ) else (
    @call %SDK_XSETTINGS%
    @set SDK_AVAILABLE=1
  )
  @set SDK_XSETTINGS_ISDONE=1
)
@if  %LABTOOL_AVAILABLE%==0 (
  @if not defined LABTOOL_XSETTINGS_ISDONE ( @echo -- Info: Configure Xilinx LabTools Settings --
    @if not exist %LABTOOL_XSETTINGS% ( @echo --     Warning : %LABTOOL_XSETTINGS% not found --
    ) else (
      @call %LABTOOL_XSETTINGS%
      @set LABTOOL_AVAILABLE=1
    )
    @set LABTOOL_XSETTINGS_ISDONE=1
  )
)
@if  %ENABLE_SDSOC%==1 (
  @if not defined SDSOC_XSETTINGS_ISDONE  ( @echo -- Info: Configure Xilinx SDSoC Settings --
    @if not exist %SDSOC_XSETTINGS% ( @echo --     Critical Warning : %SDSOC_XSETTINGS% not found --
    ) else (
      @call %SDSOC_XSETTINGS%
      @set SDSOC_AVAILABLE=1
    )
    @set SDSOC_XSETTINGS_ISDONE=1
  )
)

@REM # -----------------
@REM # --- delete request if old project exits
@echo ----------------------check old project exists--------------------------
@set vivado_p_folder=%batchfile_path%vivado

@REM @if exist %vivado_p_folder% ( @echo Old vivado project was found: Create project will delete older project!
@REM @goto  before_uinput
@REM )  
@REM @goto  after_uinput
@REM :before_uinput
@REM @set /p creatProject="Are you sure to continue? (y/N):"
@REM @echo User Input: "%creatProject%"
@REM @if not "%creatProject%"=="y" (GOTO EOF)
@REM :after_uinput
@echo Start Tester..."
@echo ----------------------Change to log folder--------------------------
@REM vlog folder
@set vlog_folder=%batchfile_path%v_log
@echo %vlog_folder%
@if not exist %vlog_folder% ( @mkdir %vlog_folder% )   
@cd %vlog_folder%
@echo --------------------------------------------------------------------
@echo -------------------------Start VIVADO scripts -----------------------
@if %LABTOOL_AVAILABLE%==1 (
  @echo -------------------------start lab tools -----------------------
  start /max vivado_lab -source ../scripts/script_main.tcl  -mode batch -notrace -tclargs --run_te_procedure {TE::TESTER::external_start} --boardpart %PARTNUMBER%
) else (
  start /max vivado -source ../scripts/script_main.tcl  -mode batch -notrace -tclargs --run_te_procedure {TE::TESTER::external_start} --boardpart %PARTNUMBER%
)
@REM start /max  vivado -source ../scripts/script_main.tcl  -mode batch -notrace -tclargs --run_board_selection


@echo -------------------------scripts finished----------------------------
@echo --------------------------------------------------------------------
@echo --------------------Change to design folder-------------------------
@cd..
@echo ------------------------Design finished-----------------------------


@GOTO LAST_DESCR

:SPECIFY_XILINX_DIR
@set /p new_cmd=" Please specifiy you Xilinx base installation folder (ex. c:/xilinx): "
@set XILDIR=%new_cmd%
@GOTO XILINX_PATH


:SPECIFY_VIVADO_VERSION
@set /p new_cmd=" Please specifiy your Vivado version (ex. %VIVADO_VERSION%): "
@set VIVADO_VERSION=%new_cmd%
@set ckeckvivfolder=1
@GOTO XILINX_PATH


@REM ------------------------------------------------------------------------------
:LAST_DESCR
@if not exist %batchfile_path%design_basic_settings.cmd ( @copy %cmd_folder%design_basic_settings.cmd %batchfile_path%design_basic_settings.cmd)
@if not exist %batchfile_path%_use_virtual_drive.cmd    ( @copy %cmd_folder%_use_virtual_drive.cmd %batchfile_path%_use_virtual_drive.cmd)

@echo --------------------------------------------------------------------
@GOTO EOF
@REM ------------------------------------------------------------------------------
:ERROR
@echo ---------------------------Error occurs-----------------------------
@echo --------------------------------------------------------------------
@PAUSE
@REM ------------------------------------------------------------------------------

:EOF
@echo ------------------------------Finished------------------------------
@echo --------------------------------------------------------------------
@PAUSE

