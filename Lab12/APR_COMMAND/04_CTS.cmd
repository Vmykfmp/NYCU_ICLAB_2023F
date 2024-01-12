## ========================================================
## Project:  iclab APR Flow
## File:     04_CTS.cmd
## Author:   Hsu Tse-Chun
## ========================================================

# =================================== #
#        PRECTS TIMING REPORT         #
# =================================== #
redirect -quiet {set honorDomain [getAnalysisMode -honorClockDomains]} > /dev/null
timeDesign -preCTS -pathReports -drvReports -slackReports -numPaths 50 -prefix CHIP_preCTS -outDir timingReports

# =================================== #
#        CLOCK TREE SYNTHESIS         #
# =================================== #
source cmd/ccopt.cmd

# =================================== #
#       POSTCTS TIMING REPORT         #
# =================================== #
redirect -quiet {set honorDomain [getAnalysisMode -honorClockDomains]} > /dev/null
timeDesign -postCTS -pathReports -drvReports -slackReports -numPaths 50 -prefix CHIP_postCTS -outDir timingReports
redirect -quiet {set honorDomain [getAnalysisMode -honorClockDomains]} > /dev/null
timeDesign -postCTS -hold -pathReports -slackReports -numPaths 50 -prefix CHIP_postCTS -outDir timingReports

# =================================== #
#           ADD PAD FILLER            #
# =================================== #
source ./cmd/addIOFiller.cmd

# =================================== #
#             SAVE DESIGN             #
# =================================== #
saveDesign ./DBS/CHIP_postCTS.inn
