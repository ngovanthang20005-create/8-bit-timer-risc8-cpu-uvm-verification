# usage: make plain | make lint | make uvm SIM=questa|vcs|xcelium TEST=tmr_all_test
#        make mutate           (plain testbench with each planted bug)
TEST ?= tmr_all_test
SIM  ?= questa
SEED ?= 1
BUG  ?=

plain:
	sh run_plain.sh $(BUG)

mutate:
	@for b in BUG_OVF BUG_PWM BUG_CMP BUG_ONESHOT BUG_W1C; do \
	  echo "== $$b"; sh run_plain.sh -D$$b | grep -E "checker:|PASSED|FAILED"; done

lint:
	verilator --lint-only -Wall ../rtl/timer8.v ../rtl/timer_regs.v ../rtl/timer_top.v --top-module timer_top

uvm:
ifeq ($(SIM),questa)
	vlib work && vlog -sv -mfcu -f filelist.f +define+UVM_NO_DPI && \
	vsim -c tb_top +UVM_TESTNAME=$(TEST) -sv_seed $(SEED) -do "run -all; quit" -coverage
else ifeq ($(SIM),vcs)
	vcs -sverilog -ntb_opts uvm-1.2 -f filelist.f -top tb_top -o simv && ./simv +UVM_TESTNAME=$(TEST) +ntb_random_seed=$(SEED)
else ifeq ($(SIM),xcelium)
	xrun -uvm -sv -f filelist.f -top tb_top +UVM_TESTNAME=$(TEST) -svseed $(SEED)
endif

regress:
	@for t in tmr_reg_test tmr_periodic_test tmr_oneshot_test tmr_pwm_test tmr_edge_test tmr_irq_test tmr_random_test tmr_all_test; do \
	  $(MAKE) -s uvm TEST=$$t SIM=$(SIM) | grep -E "RESULT|UVM_ERROR :|UVM_FATAL :"; done
