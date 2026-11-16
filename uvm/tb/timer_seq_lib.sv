// ---------------- base sequence with helpers ----------------
class tmr_base_seq extends uvm_sequence #(bus_item);
  `uvm_object_utils(tmr_base_seq)
  function new(string name = "tmr_base_seq"); super.new(name); endfunction

  task wr(bit [3:0] a, bit [7:0] d, int g = 0);
    bus_item it = bus_item::type_id::create("it");
    start_item(it);
    if (!it.randomize() with {idle == 0; we == 1; addr == a; wdata == d; gap == g;}) `uvm_fatal("RND", "wr")
    finish_item(it);
  endtask
  task rd(bit [3:0] a, output bit [7:0] v, input int g = 0);
    bus_item it = bus_item::type_id::create("it");
    start_item(it);
    if (!it.randomize() with {idle == 0; we == 0; addr == a; wdata == 0; gap == g;}) `uvm_fatal("RND", "rd")
    finish_item(it);
    v = it.rdata;
  endtask
  task idle(int n);
    bus_item it = bus_item::type_id::create("it");
    start_item(it);
    if (!it.randomize() with {idle == 1; gap == n;}) `uvm_fatal("RND", "idle")
    finish_item(it);
  endtask
  task cfg(bit [7:0] p, bit [7:0] l, bit [7:0] c);
    wr(4'h0, 8'h00); wr(4'h1, p); wr(4'h2, l); wr(4'h3, c);
  endtask
endclass

// ---------------- registers ----------------
class tmr_reg_seq extends tmr_base_seq;
  `uvm_object_utils(tmr_reg_seq)
  function new(string name = "tmr_reg_seq"); super.new(name); endfunction
  task body();
    bit [7:0] v;
    for (int a = 0; a < 16; a++) rd(a[3:0], v);                    // reset values (SB checks)
    for (int b = 0; b < 8; b++) begin                              // walking ones on RW registers
      wr(4'h1, 8'h1 << b); rd(4'h1, v);
      wr(4'h2, 8'h1 << b); rd(4'h2, v);
      wr(4'h3, 8'h1 << b); rd(4'h3, v);
      wr(4'hD, 8'h1 << b); rd(4'hD, v);
    end
    wr(4'h4, 8'hAA); rd(4'h4, v);                                  // RO ignores writes
    wr(4'hF, 8'hAA); rd(4'hF, v);
    for (int a = 5; a <= 12; a++) begin wr(a[3:0], 8'hFF); rd(a[3:0], v); end   // unused
  endtask
endclass

// ---------------- periodic ----------------
class tmr_periodic_seq extends tmr_base_seq;
  `uvm_object_utils(tmr_periodic_seq)
  function new(string name = "tmr_periodic_seq"); super.new(name); endfunction
  task body();
    bit [7:0] v;
    int p[$] = '{0, 0, 0, 1, 3, 7, 2};
    int l[$] = '{0, 1, 5, 4, 24, 9, 255};
    foreach (p[i]) begin
      cfg(p[i], l[i], (l[i] / 2));
      wr(4'h0, 8'h01);
      repeat (4) begin idle(((p[i]+1)*(l[i]+1)) / 3 + 1); rd(4'h4, v); end
      wr(4'h0, 8'h00); idle(2);
    end
  endtask
endclass

// ---------------- one-shot ----------------
class tmr_oneshot_seq extends tmr_base_seq;
  `uvm_object_utils(tmr_oneshot_seq)
  function new(string name = "tmr_oneshot_seq"); super.new(name); endfunction
  task body();
    bit [7:0] v;
    repeat (3) begin
      cfg(1, 4, 2);
      wr(4'h0, 8'h03);
      idle(60);
      rd(4'h0, v); rd(4'h4, v); rd(4'hE, v);
      wr(4'hE, 8'h03);
    end
    cfg(0, 0, 0); wr(4'h0, 8'h03); idle(10); rd(4'h0, v);     // fastest one-shot
  endtask
endclass

// ---------------- PWM ----------------
class tmr_pwm_seq extends tmr_base_seq;
  `uvm_object_utils(tmr_pwm_seq)
  function new(string name = "tmr_pwm_seq"); super.new(name); endfunction
  task body();
    int c[$] = '{0, 1, 3, 9, 10, 200};
    foreach (c[i]) begin
      cfg(1, 9, c[i]); wr(4'h0, 8'h01); idle(70); wr(4'h0, 8'h00); idle(2);
    end
  endtask
endclass

// ---------------- edge cases ----------------
class tmr_edge_seq extends tmr_base_seq;
  `uvm_object_utils(tmr_edge_seq)
  function new(string name = "tmr_edge_seq"); super.new(name); endfunction
  task body();
    bit [7:0] v;
    cfg(255, 1, 1); wr(4'h0, 8'h01); idle(600); wr(4'h0, 8'h00);      // PRESC = 255
    cfg(0, 200, 5); wr(4'h0, 8'h01); idle(50); wr(4'h2, 8'd3); idle(300); wr(4'h0, 8'h00);  // LOAD < CNT
    cfg(5, 9, 4); wr(4'h0, 8'h01); idle(30); wr(4'h1, 8'd0); idle(30); wr(4'h0, 8'h00);     // PRESC live
    cfg(0, 9, 4); wr(4'h0, 8'h01); idle(13); wr(4'h0, 8'h00); rd(4'h4, v); idle(5);          // disable mid-run
    cfg(0, 9, 4); wr(4'h0, 8'h01); idle(13); wr(4'h0, 8'h01); idle(30); wr(4'h0, 8'h00);     // rewrite EN=1 (no restart)
  endtask
endclass

// ---------------- interrupts + race ----------------
class tmr_irq_seq extends tmr_base_seq;
  `uvm_object_utils(tmr_irq_seq)
  function new(string name = "tmr_irq_seq"); super.new(name); endfunction
  task body();
    bit [7:0] v;
    cfg(0, 3, 2); wr(4'hE, 8'h03); wr(4'hD, 8'h03); wr(4'h0, 8'h01); idle(20);
    rd(4'hE, v); wr(4'h0, 8'h00); wr(4'hE, 8'h03); rd(4'hE, v);
    wr(4'hD, 8'h00); wr(4'h0, 8'h01); idle(20); rd(4'hE, v); wr(4'h0, 8'h00); wr(4'hE, 8'h03);
    // RACE: W1C every clock while events happen -> the event must win
    wr(4'hD, 8'h03); wr(4'h0, 8'h01);
    repeat (40) wr(4'hE, 8'h03);
    for (int off = 0; off < 6; off++) begin idle(off); repeat (6) wr(4'hE, 8'h01 << (off % 2)); end
    wr(4'h0, 8'h00); wr(4'hE, 8'h03);
  endtask
endclass

// ---------------- random ----------------
class tmr_random_seq extends tmr_base_seq;
  `uvm_object_utils(tmr_random_seq)
  rand int unsigned n = 2000;
  function new(string name = "tmr_random_seq"); super.new(name); endfunction
  task body();
    bus_item it;
    repeat (n) begin
      it = bus_item::type_id::create("it");
      start_item(it);
      if (!it.randomize() with {
            idle dist {0 := 9, 1 := 1};
            addr dist {[0:3] := 4, 4'hD := 1, 4'hE := 2, [4:15] := 1};
            (addr inside {1, 2}) -> wdata dist {[0:7] := 8, [8:255] := 2};
            (addr == 0) -> wdata[7:2] == 0;
            (addr == 0 && we) -> wdata[0] dist {0 := 1, 1 := 4};
            gap dist {0 := 7, [1:4] := 3};
          }) `uvm_fatal("RND", "random")
      finish_item(it);
    end
  endtask
endclass
