class timer_coverage extends uvm_subscriber #(bus_item);
  `uvm_component_utils(timer_coverage)
  bit [7:0] presc, load, cmp, ie;
  bit       os;
  bit [7:0] cur_addr, cur_data; bit cur_we;

  covergroup cg_reg;
    cp_addr : coverpoint cur_addr { bins regs[] = {0,1,2,3,4,13,14,15}; bins unused = {[5:12]}; }
    cp_we   : coverpoint cur_we;
    x_addr_we : cross cp_addr, cp_we;
  endgroup

  covergroup cg_start;     // sampled whenever CTRL is written with EN=1
    cp_presc : coverpoint presc { bins zero = {0}; bins one = {1}; bins low_rng = {[2:15]}; bins high_rng = {[16:255]}; }
    cp_load  : coverpoint load  { bins zero = {0}; bins one = {1}; bins mid = {[2:254]}; bins max = {255}; }
    cp_cmp_rel : coverpoint (cmp == 0 ? 0 : (cmp < load ? 1 : (cmp == load ? 2 : 3))) {
                   bins cmp_zero = {0}; bins below = {1}; bins equal = {2}; bins above = {3}; }
    cp_mode  : coverpoint os { bins periodic = {0}; bins oneshot = {1}; }
    cp_ie    : coverpoint ie[1:0];
    x_mode_presc : cross cp_mode, cp_presc;
    x_mode_load  : cross cp_mode, cp_load;
  endgroup

  function new(string n, uvm_component p);
    super.new(n, p); cg_reg = new(); cg_start = new();
    load = 8'hFF; cmp = 8'h80;
  endfunction

  function void write(bus_item t);
    cur_addr = t.addr; cur_we = t.we; cur_data = t.wdata;
    cg_reg.sample();
    if (t.we) begin
      case (t.addr)
        4'h1: presc = t.wdata;
        4'h2: load  = t.wdata;
        4'h3: cmp   = t.wdata;
        4'hD: ie    = t.wdata;
        4'h0: begin os = t.wdata[1]; if (t.wdata[0]) cg_start.sample(); end
        default: ;
      endcase
    end
  endfunction

  function void report_phase(uvm_phase phase);
    `uvm_info("COV", $sformatf("cg_reg=%.1f%% cg_start=%.1f%%", cg_reg.get_inst_coverage(), cg_start.get_inst_coverage()), UVM_LOW)
  endfunction
endclass
