// timer_top.v - the block the CPU connects to (one-clock bus: cs/we/addr/wdata -> rdata)
module timer_top (
  input  wire       clk,
  input  wire       rst_n,
  input  wire       cs,
  input  wire       we,
  input  wire [3:0] addr,
  input  wire [7:0] wdata,
  output wire [7:0] rdata,     // 0 when cs = 0 (can be OR-ed with other devices)
  output wire       irq,
  output wire       pwm_out,
  // debug taps (used by checker / assertions; leave open in the SoC)
  output wire       ovf_ev,
  output wire       cmp_ev,
  output wire [7:0] cnt
);
  wire       en;
  /* verilator lint_off UNUSEDSIGNAL */
  wire       oneshot;      // only used by the bound assertions (sv/timer_sva.sv)
  /* verilator lint_on UNUSEDSIGNAL */
  wire [7:0] presc, load, cmp;

  timer_regs u_regs (.clk(clk), .rst_n(rst_n), .cs(cs), .we(we), .addr(addr),
                     .wdata(wdata), .rdata(rdata), .en(en), .oneshot(oneshot),
                     .presc(presc), .load(load), .cmp(cmp), .cnt(cnt),
                     .ovf_ev(ovf_ev), .cmp_ev(cmp_ev), .irq(irq));

  timer8 u_timer (.clk(clk), .rst_n(rst_n), .en(en), .presc(presc), .load(load),
                  .cmp(cmp), .cnt(cnt), .ovf_ev(ovf_ev), .cmp_ev(cmp_ev),
                  .pwm_out(pwm_out));
endmodule
