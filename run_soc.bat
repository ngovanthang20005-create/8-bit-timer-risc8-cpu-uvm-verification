@echo off
cd /d "%~dp0"
echo [1/3] Assembling sw\timer_demo.s
python sw\asm8.py sw\timer_demo.s timer_demo.hex > nul
echo [2/3] Compiling (file list in files_soc.f)
iverilog -g2005 -o soc.vvp -c files_soc.f
echo [3/3] Running simulation
vvp soc.vvp
