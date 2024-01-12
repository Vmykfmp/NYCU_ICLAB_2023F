## ========================================================
## Project:  iclab APR Flow
## File:     06_postRoute.cmd
## Author:   Hsu Tse-Chun
## ========================================================

# =================================== #
#            MODE SETTING             #
# =================================== #
setAnalysisMode -cppr none -clockGatingCheck true -timeBorrowing true -useOutputPinCap true -sequentialConstProp false -timingSelfLoopsNoSkew false -enableMultipleDriveNet true -clkSrcPath true -warn true -usefulSkew true -analysisType onChipVariation -log true
setExtractRCMode -engine postRoute -effortLevel signoff -coupled true -capFilterMode relOnly -coupling_c_th 3 -total_c_th 5 -relative_c_th 0.03 -lefTechFileMap /RAID2/COURSE/iclab/iclab059/Lab13/Exercise/05_APR/layermap/lefdef.layermap.cmd
setExtractRCMode -engine postRoute
setExtractRCMode -effortLevel high
setDelayCalMode -SIAware true

# =================================== #
#       POSTROUTE TIMING REPORT       #
# =================================== #
redirect -quiet {set honorDomain [getAnalysisMode -honorClockDomains]} > /dev/null
timeDesign -postRoute -pathReports -drvReports -slackReports -numPaths 50 -prefix CHIP_postRoute -outDir timingReports
redirect -quiet {set honorDomain [getAnalysisMode -honorClockDomains]} > /dev/null
timeDesign -postRoute -hold -pathReports -slackReports -numPaths 50 -prefix CHIP_postRoute -outDir timingReports

# =================================== #
#             SAVE DESIGN             #
# =================================== #
saveDesign ./DBS/CHIP_postRoute.inn
