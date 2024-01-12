## ========================================================
## Project:  iclab APR Flow
## File:     07_timingAnalysis.cmd
## Author:   Hsu Tse-Chun
## ========================================================

# =================================== #
#        SIGNOFF TIMING REPORT        #
# =================================== #
redirect -quiet {set honorDomain [getAnalysisMode -honorClockDomains]} > /dev/null
timeDesign -signoff -pathReports -drvReports -slackReports -numPaths 50 -prefix CHIP_signOff -outDir timingReports
redirect -quiet {set honorDomain [getAnalysisMode -honorClockDomains]} > /dev/null
timeDesign -signoff -hold -pathReports -slackReports -numPaths 50 -prefix CHIP_signOff -outDir timingReports
