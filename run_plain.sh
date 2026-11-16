#!/bin/sh
# usage: sh run_plain.sh [-DBUG_OVF|-DBUG_PWM|-DBUG_CMP|-DBUG_ONESHOT|-DBUG_W1C]
cd "$(dirname "$0")"
iverilog -g2012 $1 -o /tmp/tb_plain.vvp rtl/periph/timer8.v rtl/periph/timer_regs.v rtl/periph/timer_top.v \
  sv/timer_ref.v sv/timer_checker.v tb/tb_plain.v && vvp /tmp/tb_plain.vvp
