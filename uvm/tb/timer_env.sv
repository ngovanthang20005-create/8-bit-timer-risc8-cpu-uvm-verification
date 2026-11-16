class timer_env extends uvm_env;
  `uvm_component_utils(timer_env)
  bus_agent        agent;
  timer_scoreboard sb;
  timer_coverage   cov;
  function new(string n, uvm_component p); super.new(n, p); endfunction
  function void build_phase(uvm_phase phase);
    agent = bus_agent       ::type_id::create("agent", this);
    sb    = timer_scoreboard::type_id::create("sb", this);
    cov   = timer_coverage  ::type_id::create("cov", this);
  endfunction
  function void connect_phase(uvm_phase phase);
    agent.mon.ap.connect(sb.analysis_export);
    agent.mon.ap.connect(cov.analysis_export);
  endfunction
endclass
