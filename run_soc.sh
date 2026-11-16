#!/bin/sh
# One-click system simulation (Linux/macOS). Needs python3 and iverilog.
set -e
cd "$(dirname "$0")"
echo "[1/3] Assembling sw/timer_demo.s -> timer_demo.hex"
python3 sw/asm8.py sw/timer_demo.s timer_demo.hex > /dev/null
echo "[2/3] Compiling (file list in files_soc.f)"
iverilog -g2005 -o soc.vvp -c files_soc.f
echo "[3/3] Running simulation"
vvp soc.vvp | grep -v "^VCD"
