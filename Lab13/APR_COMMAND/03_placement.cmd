## ========================================================
## Project:  iclab APR Flow
## File:     03_placement.cmd
## Author:   Hsu Tse-Chun
## ========================================================

# =================================== #
#        PLACE STANDARD CELLS         #
# =================================== #
setPlaceMode -prerouteAsObs {2 3}
setPlaceMode -fp false
place_design -noPrePlaceOpt
setDrawView place

# =================================== #
#             SAVE DESIGN             #
# =================================== #
saveDesign ./DBS/CHIP_placement.inn

