@echo off
setlocal EnableDelayedExpansion
if not [%1]==[] (
echo command line arguments are used as scenarios
set list=%*
) else (
echo default arguments are used
set list=Germany_Stuttgart Finnland_Helsinki Canada_Ottawa
)
echo the following scenarios will be computed:
echo %list%
for %%i in (%list%) do (
if not exist %%i (
echo no scenario folder found for %%i
) else (
if not exist %%i\data_output mkdir %%i\data_output
if not exist %%i\plots mkdir %%i\plots
echo COMPUTING SCENARIO %%i
)
)
echo computations complete
