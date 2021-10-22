@echo off
setlocal EnableDelayedExpansion
if not [%1]==[] (
echo command line arguments are used as scenarios
set list=%*
) else (
echo default arguments are used
set list=Germany_Stuttgart Argentina_RioGrande Sudan_Karthoum
)
echo STARTING COMPUTATION
echo the following scenarios will be computed:
echo %list%
for %%i in (%list%) do (
if not exist scenarios\%%i (
echo no scenario folder found for %%i
) else (
if not exist scenarios\%%i\data_output mkdir scenarios\%%i\data_output
if not exist scenarios\%%i\plots mkdir scenarios\%%i\plots
echo COMPUTING SCENARIO %%i
echo here should be invocation of gams and plotting
)
)
echo ALL COMPUTATIONS COMPLETE
