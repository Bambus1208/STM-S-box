@echo off
if "%~1"=="" (
    echo Please enter the file name as a parameter.
    exit /b
)
iverilog.exe -o temp %1
vvp .\temp
gtkwave.exe .\dump.vcd
