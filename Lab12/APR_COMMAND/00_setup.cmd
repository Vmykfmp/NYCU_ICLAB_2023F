## ========================================================
## Project:  iclab APR Flow
## File:     00_setup.cmd
## Author:   Hsu Tse-Chun
## ========================================================

# =================================== #
#          PARAMATER SETTING          #
# =================================== #
set ProcessRoot "/RAID2/COURSE/iclab/iclab059/Lab13/Exercise/05_APR"
set NUM_OF_CPU 48
set mmmcFile "CHIP_mmmc.view"
set lefFile "
    $ProcessRoot/LEF/header6_V55_20ka_cic.lef
    $ProcessRoot/LEF/fsa0m_a_generic_core.lef
    $ProcessRoot/LEF/FSA0M_A_GENERIC_CORE_ANT_V55.lef
    $ProcessRoot/LEF/fsa0m_a_t33_generic_io.lef
    $ProcessRoot/LEF/FSA0M_A_T33_GENERIC_IO_ANT_V55.lef
    $ProcessRoot/LEF/BONDPAD.lef
"
set topDesign "CHIP"
set verilogFile "./CHIP_SYN.v"
set ioFile "./CHIP.io"
set pwrNet "VCC"
set gndNet "GND"

# =================================== #
#         APR UMC018 SETTING          #
# =================================== #
set init_design_uniquify 1
setDesignMode -process 180
suppressMessage TECHLIB 1318
suppressMessage ENCEXT-2799

# =================================== #
#        DESIGN INITIALIZATION        #
# =================================== #
set init_mmmc_file $mmmcFile
set init_lef_file $lefFile
set init_verilog $verilogFile
set init_top_cell $topDesign
set init_io_file $ioFile
set init_pwr_net $pwrNet
set init_gnd_net $gndNet
init_design -setup {av_func_mode_max} -hold {av_func_mode_min}

# =================================== #
#            SAVE GLOBALS             #
# =================================== #
save_global CHIP.globals
win

fit