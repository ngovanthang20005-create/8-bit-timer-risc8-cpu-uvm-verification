// Scoreboard: (1) static register checks from observed bus traffic,
//             (2) per-clock behaviour result of timer_checker (reference model) at the end.
class timer_scoreboard extends uvm_subscriber #(bus_item);
  `uvm_component_utils(timer_scoreboard)
  virtual bus_if vif;
  bit [7:0] m_presc = 8'h00, m_load = 8'hFF, m_cmp = 8'h80;
  bit [1:0] m_ie = 0;  bit m_os = 0;
  int n_wr, n_rd, n_err;

  function new(string n, uvm_component p); super.new(n, p); endfunction
  function void build_phase(uvm_phase phase);
    if (!uvm_config_db#(virtual bus_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "bus_if not set")
  endfunction

  function void chk(bit [7:0] got, bit [7:0] exp, string what);
    if (got !== exp) begin n_err++; `uvm_error("SB", $sformatf("%s: got %02h expected %02h", what, got, exp)) end
  endfunction

  function void write(bus_item t);
    if (t.we) begin
      n_wr++;
      case (t.addr)
        4'h0: m_os    = t.wdata[1];
        4'h1: m_presc = t.wdata;
        4'h2: m_load  = t.wdata;
        4'h3: m_cmp   = t.wdata;
        4'hD: m_ie    = t.wdata[1:0];
        default: ;
      endcase
    end else begin
      n_rd++;
      case (t.addr)
        4'h0: chk(t.rdata[7:1], {6'b0, m_os}, "TMR_CTRL[7:1]");   
        4'h1: chk(t.rdata, m_presc, "TMR_PRESC");
        4'h2: chk(t.rdata, m_load,  "TMR_LOAD");
        4'h3: chk(t.rdata, m_cmp,   "TMR_CMP");
        4'hD: chk(t.rdata, {6'b0, m_ie}, "IRQ_EN");
        4'hE: chk(t.rdata[7:2], 6'h0, "IRQ_STAT upper bits");
        4'hF: chk(t.rdata, 8'h54, "ID");
        4'h4: ;                                                    
        default: chk(t.rdata, 8'h00, "unused register");
      endcase
    end
  endfunction

  function void report_phase(uvm_phase phase);
    `uvm_info("SB", $sformatf("writes=%0d reads=%0d reg-check errors=%0d | per-clock checks=%0d mismatches=%0d",
              n_wr, n_rd, n_err, vif.chk_checks, vif.chk_errors), UVM_LOW)
    if (vif.chk_checks == 0) `uvm_error("SB", "reference-model checker never ran")
    if (vif.chk_errors != 0) `uvm_error("SB", $sformatf("%0d per-clock mismatches vs reference model", vif.chk_errors))
  endfunction
endclass
