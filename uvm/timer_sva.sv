// Assertions, attached to timer_top with bind.
// Each property carries its own clock and disable iff (xsim lacks the default forms).
module timer_sva (
  input logic       clk, rst_n, cs,
  input logic [7:0] rdata, cnt, cmp,
  input logic       en, oneshot, ovf_ev, cmp_ev, pwm_out
);
  a_en0_cnt  : assert property (@(posedge clk) disable iff (!rst_n) !en |=> cnt == 8'd0)
               else $error("SVA: EN=0 but cnt != 0");
  a_en0_pwm  : assert property (@(posedge clk) disable iff (!rst_n) !en |-> !pwm_out)
               else $error("SVA: PWM high while EN=0");
  a_ovf_wrap : assert property (@(posedge clk) disable iff (!rst_n) ovf_ev |=> cnt == 8'd0)
               else $error("SVA: no wrap after OVF");
  a_cmp_match: assert property (@(posedge clk) disable iff (!rst_n) cmp_ev |-> cnt == cmp)
               else $error("SVA: cmp_ev but cnt != cmp");
  a_pwm_def  : assert property (@(posedge clk) disable iff (!rst_n) pwm_out |-> (en && cnt < cmp))
               else $error("SVA: PWM compare wrong");
  a_oneshot  : assert property (@(posedge clk) disable iff (!rst_n) (ovf_ev && oneshot) |=> !en)
               else $error("SVA: one-shot did not stop");
  a_rdata0   : assert property (@(posedge clk) disable iff (!rst_n) !cs |-> rdata == 8'h00)
               else $error("SVA: rdata != 0 when cs = 0");
endmodule
bind timer_top timer_sva u_sva (.*);
