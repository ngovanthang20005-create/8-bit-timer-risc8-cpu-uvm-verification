class tmr_base_test extends uvm_test;
  `uvm_component_utils(tmr_base_test)
  timer_env env;
  function new(string n, uvm_component p); super.new(n, p); endfunction
  function void build_phase(uvm_phase phase); env = timer_env::type_id::create("env", this); endfunction
  virtual task body(); endtask
  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    body();
    #200ns;
    phase.drop_objection(this);
  endtask
  function void report_phase(uvm_phase phase);
    uvm_report_server rs = uvm_report_server::get_server();
    if (rs.get_severity_count(UVM_ERROR) + rs.get_severity_count(UVM_FATAL) == 0)
      `uvm_info("RESULT", "*** TEST PASSED ***", UVM_NONE)
    else
      `uvm_info("RESULT", "*** TEST FAILED ***", UVM_NONE)
  endfunction
endclass

`define TMR_TEST(NAME, SEQ) \
class NAME extends tmr_base_test; \
  `uvm_component_utils(NAME) \
  function new(string n, uvm_component p); super.new(n, p); endfunction \
  task body(); SEQ s = SEQ::type_id::create("s"); s.start(env.agent.sqr); endtask \
endclass

`TMR_TEST(tmr_reg_test,      tmr_reg_seq)
`TMR_TEST(tmr_periodic_test, tmr_periodic_seq)
`TMR_TEST(tmr_oneshot_test,  tmr_oneshot_seq)
`TMR_TEST(tmr_pwm_test,      tmr_pwm_seq)
`TMR_TEST(tmr_edge_test,     tmr_edge_seq)
`TMR_TEST(tmr_irq_test,      tmr_irq_seq)
`TMR_TEST(tmr_random_test,   tmr_random_seq)

class tmr_all_test extends tmr_base_test;
  `uvm_component_utils(tmr_all_test)
  function new(string n, uvm_component p); super.new(n, p); endfunction
  task body();
    tmr_reg_seq      s0 = tmr_reg_seq     ::type_id::create("s0");
    tmr_periodic_seq s1 = tmr_periodic_seq::type_id::create("s1");
    tmr_oneshot_seq  s2 = tmr_oneshot_seq ::type_id::create("s2");
    tmr_pwm_seq      s3 = tmr_pwm_seq     ::type_id::create("s3");
    tmr_edge_seq     s4 = tmr_edge_seq    ::type_id::create("s4");
    tmr_irq_seq      s5 = tmr_irq_seq     ::type_id::create("s5");
    tmr_random_seq   s6 = tmr_random_seq  ::type_id::create("s6");
    s0.start(env.agent.sqr); s1.start(env.agent.sqr); s2.start(env.agent.sqr);
    s3.start(env.agent.sqr); s4.start(env.agent.sqr); s5.start(env.agent.sqr);
    s6.start(env.agent.sqr);
  endtask
endclass
