// ---------------- item ----------------
class bus_item extends uvm_sequence_item;
  rand bit          idle;      // 1 = no bus access, just wait 'gap' clocks
  rand bit          we;
  rand bit [3:0]    addr;
  rand bit [7:0]    wdata;
  rand int unsigned gap;       // idle clocks after (or for) this item
  bit [7:0]         rdata;     // filled by driver/monitor for reads

  // c_gap removed (it broke idle(n) for n>20)
  `uvm_object_utils_begin(bus_item)
    `uvm_field_int(idle, UVM_DEFAULT) `uvm_field_int(we, UVM_DEFAULT)
    `uvm_field_int(addr, UVM_DEFAULT) `uvm_field_int(wdata, UVM_DEFAULT)
    `uvm_field_int(rdata, UVM_DEFAULT) `uvm_field_int(gap, UVM_DEFAULT)
  `uvm_object_utils_end
  function new(string name = "bus_item"); super.new(name); endfunction
endclass

// ---------------- driver ----------------
class bus_driver extends uvm_driver #(bus_item);
  `uvm_component_utils(bus_driver)
  virtual bus_if vif;
  time last_edge = 0;
  function new(string n, uvm_component p); super.new(n, p); endfunction
  function void build_phase(uvm_phase phase);
    if (!uvm_config_db#(virtual bus_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "bus_if not set")
  endfunction
  task run_phase(uvm_phase phase);
    vif.drv_cb.cs <= 0; vif.drv_cb.we <= 0; vif.drv_cb.addr <= 0; vif.drv_cb.wdata <= 0;
    wait (vif.rst_n === 1'b1);
    forever begin
      seq_item_port.get_next_item(req);
      if ($time != last_edge) @(vif.drv_cb);          // align to a clock edge
      if (req.idle) begin
        vif.drv_cb.cs <= 0; vif.drv_cb.we <= 0;
        repeat (req.gap) @(vif.drv_cb);
      end else begin
        vif.drv_cb.cs <= 1; vif.drv_cb.we <= req.we;
        vif.drv_cb.addr <= req.addr; vif.drv_cb.wdata <= req.wdata;
        @(vif.drv_cb);                                  // DUT samples this edge
        if (!req.we) req.rdata = vif.drv_cb.rdata;      // comb read data of that cycle
        vif.drv_cb.cs <= 0; vif.drv_cb.we <= 0;
        repeat (req.gap) @(vif.drv_cb);
      end
      last_edge = $time;
      seq_item_port.item_done();
    end
  endtask
endclass

// ---------------- monitor ----------------
class bus_monitor extends uvm_monitor;
  `uvm_component_utils(bus_monitor)
  virtual bus_if vif;
  uvm_analysis_port #(bus_item) ap;
  function new(string n, uvm_component p); super.new(n, p); endfunction
  function void build_phase(uvm_phase phase);
    ap = new("ap", this);
    if (!uvm_config_db#(virtual bus_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "bus_if not set")
  endfunction
  task run_phase(uvm_phase phase);
    bus_item it;
    forever begin
      @(vif.mon_cb);
      if (vif.rst_n === 1'b1 && vif.mon_cb.cs === 1'b1) begin
        it = bus_item::type_id::create("mon_it");
        it.we = vif.mon_cb.we; it.addr = vif.mon_cb.addr;
        it.wdata = vif.mon_cb.wdata; it.rdata = vif.mon_cb.rdata;
        ap.write(it);
      end
    end
  endtask
endclass

// ---------------- agent ----------------
class bus_agent extends uvm_agent;
  `uvm_component_utils(bus_agent)
  uvm_sequencer #(bus_item) sqr;
  bus_driver  drv;
  bus_monitor mon;
  function new(string n, uvm_component p); super.new(n, p); endfunction
  function void build_phase(uvm_phase phase);
    sqr = uvm_sequencer#(bus_item)::type_id::create("sqr", this);
    drv = bus_driver ::type_id::create("drv", this);
    mon = bus_monitor::type_id::create("mon", this);
  endfunction
  function void connect_phase(uvm_phase phase);
    drv.seq_item_port.connect(sqr.seq_item_export);
  endfunction
endclass
