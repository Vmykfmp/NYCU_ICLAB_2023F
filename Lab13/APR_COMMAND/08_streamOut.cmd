## ========================================================
## Project:  iclab APR Flow
## File:     08_streamOut.cmd
## Author:   Hsu Tse-Chun
## ========================================================

# =================================== #
#          ADD CORE FILLER            #
# =================================== #
getFillerMode -quiet
getFillerMode -quiet
addFiller -cell FILLER1 FILLER16 FILLER2 FILLER32 FILLER4 FILLER64 FILLER8 -prefix FILLER

# =================================== #
#             SAVE DESIGN             #
# =================================== #
saveDesign ./DBS/CHIP.inn
saveDesign CHIP.inn

# =================================== #
#              WRITE SDF              #
# =================================== #
all_hold_analysis_views 
all_setup_analysis_views 
write_sdf CHIP.sdf
# saveNetlist CHIP.v

# =================================== #
#            SAVE NETLIST             #
# =================================== #
saveNetlist CHIP.v
