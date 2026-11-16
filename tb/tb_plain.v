`timescale 1ns/1ps
// tb_plain.v - plain Verilog testbench (no UVM). Acts like the CPU: one-clock cs access.
// Directed tests check the FORMULAS independently of the reference model,
// the random test + timer_checker compare against the reference model every clock.
module tb_plain;
  reg clk = 0, rst_n = 0;
  always #5 clk = ~clk;

  reg        cs = 0, we = 0;
  reg  [3:0] addr = 0;
  reg  [7:0] wdata = 0;
  wire [7:0] rdata, cnt;
  wire       irq, pwm_out, ovf_ev, cmp_ev;
  wire [31:0] chk_errors, chk_checks;

  timer_top dut (.clk(clk), .rst_n(rst_n), .cs(cs), .we(we), .addr(addr), .wdata(wdata),
                 .rdata(rdata), .irq(irq), .pwm_out(pwm_out),
                 .ovf_ev(ovf_ev), .cmp_ev(cmp_ev), .cnt(cnt));

  timer_checker chk (.clk(clk), .rst_n(rst_n), .cs(cs), .we(we), .addr(addr), .wdata(wdata),
                     .d_rdata(rdata), .d_cnt(cnt), .d_ovf(ovf_ev), .d_cmp(cmp_ev),
                     .d_pwm(pwm_out), .d_irq(irq), .errors(chk_errors), .checks(chk_checks));

  // ---------------- bus tasks (drive 1 time unit after posedge) ----------------
  task wr(input [3:0] a, input [7:0] d);
    begin cs = 1; we = 1; addr = a; wdata = d; @(posedge clk); #1; cs = 0; we = 0; end
  endtask
  task rd(input [3:0] a, output [7:0] v);
    begin cs = 1; we = 0; addr = a; #2; v = rdata; @(posedge clk); #1; cs = 0; end
  endtask
  task idle(input integer n);
    begin cs = 0; we = 0; repeat (n) @(posedge clk); #1; end
  endtask

  // ---------------- measurement monitor ----------------
  integer cyc = 0, n_ovf = 0, n_cmp = 0, prev_ovf = 0, delta = 0, pw_cnt = 0, pw_last = 0;
  always @(posedge clk) begin
    cyc = cyc + 1;
    if (pwm_out) pw_cnt = pw_cnt + 1;
    if (cmp_ev) n_cmp = n_cmp + 1;
    if (ovf_ev) begin
      n_ovf = n_ovf + 1; delta = cyc - prev_ovf; prev_ovf = cyc;
      pw_last = pw_cnt; pw_cnt = 0;
    end
  end

  integer fails = 0;
  task expect_eq(input integer got, input integer exp, input [255:0] what);
    begin
      if (got !== exp) begin fails = fails + 1; $display("FAIL: %0s got %0d expected %0d", what, got, exp); end
      else $display("PASS: %0s = %0d", what, got);
    end
  endtask

  task wait_ovf(input integer n, input integer maxc);
    integer t;
    begin t = 0; while (n_ovf < n && t < maxc) begin @(posedge clk); t = t + 1; end #1; end
  endtask

  task run_periodic(input [7:0] p, input [7:0] l, input [7:0] c);
    integer exp_pwm, exp_per;
    begin
      wr(0, 8'h00); wr(1, p); wr(2, l); wr(3, c);
      n_ovf = 0; n_cmp = 0; pw_cnt = 0;
      wr(0, 8'h01);
      wait_ovf(3, 4*(p+1)*(l+1) + 20);
      exp_per = (p+1)*(l+1);
      exp_pwm = ((c < l+1) ? c : l+1) * (p+1);
      expect_eq(delta,  exp_per, "period (PRESC+1)*(LOAD+1)");
      expect_eq(pw_last, exp_pwm, "PWM high clocks");
      wr(0, 8'h00);
    end
  endtask

  // ---------------- random traffic ----------------
  reg [7:0] rv;
  task rand_cycle;
    reg [3:0] a; reg [7:0] d; integer r; reg rb;
    begin
      r = $random & 7;
      case (r) 0: a = 0; 1: a = 1; 2: a = 2; 3: a = 3; 4: a = 4'hD; 5: a = 4'hE; 6: a = 4; default: a = $random; endcase
      case ($random & 3)
        0: d = $random & 8'h03;
        1: d = $random & 8'h0F;
        default: d = $random;
      endcase
      if (a == 0 && ($random & 1)) begin rb = $random; d = {6'b0, rb, 1'b1}; end
      cs = (($random & 7) != 0); we = $random; addr = a; wdata = d;
      @(posedge clk); #1; cs = 0; we = 0;
    end
  endtask

  integer i, k;
  initial begin
    $display("== tb_plain start ==");
    repeat (3) @(posedge clk); #1; rst_n = 1; idle(2);

    // 1. reset values
    rd(0, rv); expect_eq(rv, 8'h00, "reset TMR_CTRL");
    rd(1, rv); expect_eq(rv, 8'h00, "reset TMR_PRESC");
    rd(2, rv); expect_eq(rv, 8'hFF, "reset TMR_LOAD");
    rd(3, rv); expect_eq(rv, 8'h80, "reset TMR_CMP");
    rd(4, rv); expect_eq(rv, 8'h00, "reset TMR_CNT");
    rd(4'hD, rv); expect_eq(rv, 8'h00, "reset IRQ_EN");
    rd(4'hE, rv); expect_eq(rv, 8'h00, "reset IRQ_STAT");
    rd(4'hF, rv); expect_eq(rv, 8'h54, "ID");
    rd(4'h7, rv); expect_eq(rv, 8'h00, "unused register reads 0");
    // cs = 0 -> rdata = 0
    addr = 4'hF; cs = 0; #2; expect_eq(rdata, 0, "rdata = 0 when cs = 0"); idle(1);

    // 2. periodic timer: (PRESC, LOAD, CMP)
    run_periodic(3, 24, 10);      // the 100-clock example
    run_periodic(0, 0, 0);
    run_periodic(0, 1, 1);
    run_periodic(1, 9, 3);        // 30 % duty
    run_periodic(0, 5, 5);
    run_periodic(2, 7, 200);      // CMP > LOAD -> PWM always high
    run_periodic(0, 9, 0);        // CMP = 0 -> PWM always low

    // 3. one-shot
    wr(0, 8'h00); wr(1, 1); wr(2, 4); n_ovf = 0;
    wr(0, 8'h03); idle(100);
    expect_eq(n_ovf, 1, "one-shot: exactly 1 overflow");
    rd(0, rv); expect_eq(rv, 8'h02, "one-shot: EN cleared by hardware, ONESHOT stays");
    rd(4, rv); expect_eq(rv, 0, "one-shot: count stopped at 0");
    n_ovf = 0; wr(0, 8'h03); idle(100);
    expect_eq(n_ovf, 1, "one-shot restarts after re-enable");

    // 4. interrupt flags + W1C
    wr(0, 0); wr(4'hE, 3); wr(1, 0); wr(2, 3); wr(3, 2); wr(4'hD, 3); wr(0, 1); idle(20);
    expect_eq(irq, 1, "irq high after events with IRQ_EN=3");
    rd(4'hE, rv); expect_eq(rv, 3, "IRQ_STAT = OVF|CMP");
    wr(0, 0); wr(4'hE, 3); idle(1);
    expect_eq(irq, 0, "irq low after W1C");
    rd(4'hE, rv); expect_eq(rv, 0, "IRQ_STAT cleared");
    wr(4'hD, 0); wr(0, 1); idle(20);
    expect_eq(irq, 0, "irq stays low when IRQ_EN=0");
    rd(4'hE, rv); expect_eq(rv, 3, "flags set even with IRQ_EN=0");
    wr(0, 0);

    // 5. race: W1C written every clock while events happen (event must win)
    wr(4'hE, 3); wr(4'hD, 3); wr(1, 0); wr(2, 3); wr(3, 2); wr(0, 1);
    for (k = 0; k < 40; k = k + 1) wr(4'hE, 3);
    wr(0, 0); wr(4'hE, 3);

    // 6. live reconfiguration + edge cases
    wr(1, 255); wr(2, 1); wr(0, 1); idle(300); wr(0, 0);       // big prescaler
    wr(1, 0); wr(2, 200); wr(0, 1); idle(50); wr(2, 3); idle(300); wr(0, 0);  // LOAD below CNT
    wr(2, 0); wr(1, 0); wr(0, 1); idle(20); wr(0, 0);          // LOAD = 0
    wr(1, 5); wr(2, 9); wr(0, 1); idle(30); wr(1, 0); idle(30); wr(0, 0);     // PRESC lowered live

    // 7. random traffic
    for (i = 0; i < 30000; i = i + 1) rand_cycle;
    idle(5);

    $display("checker: %0d checks, %0d mismatches vs reference model", chk_checks, chk_errors);
    if (fails == 0 && chk_errors == 0 && chk_checks > 0)
      $display("*** ALL TESTS PASSED ***");
    else
      $display("*** TESTS FAILED (directed fails=%0d, checker errors=%0d) ***", fails, chk_errors);
    $finish;
  end

  initial begin #50_000_000; $display("*** TIMEOUT ***"); $finish; end
endmodule
