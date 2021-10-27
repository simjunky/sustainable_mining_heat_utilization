@echo off
setlocal EnableDelayedExpansion
set list=
if not [%1]==[] (
echo command line arguments are used as scenarios
set list=%*
) else (
echo SEARCHING FOR SCENARIOS:
for /f "delims=" %%a in ('dir .\scenarios /A:D /B') do (
set list=!list! %%a
echo found scenario %%a
)
)
echo STARTING COMPUTATIONS
echo the following scenarios will be computed:
echo %list%
for %%i in (%list%) do (
if not exist scenarios\%%i (
echo no scenario folder found for %%i
) else (
if not exist scenarios\%%i\data_output mkdir scenarios\%%i\data_output
if not exist scenarios\%%i\plots mkdir scenarios\%%i\plots
echo COMPUTING SCENARIO: %%i
gams optimization_model.gms --SCENARIO_FOLDER=%%i
julia dataplotting.jl %%i
)
)
echo END OF COMPUTATIONS
