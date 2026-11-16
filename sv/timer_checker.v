// timer_checker.v - compares DUT with timer_ref on every clock (sampled at negedge)
module timer_checker (
  input  wire       clk, rst_n, cs, we,
  input  wire [3:0] addr,
  input  wire [7:0] wdata,
  input  wire [7:0] d_rdata, d_cnt,
  input  wire       d_ovf, d_cmp, d_pwm, d_irq,
  output reg [31:0] errors,
  output reg [31:0] checks
);
  wire [7:0] r_rdata, r_cnt;
  wire r_ovf, r_cmp, r_pwm, r_irq;
  timer_ref u_ref (.clk(clk), .rst_n(rst_n), .cs(cs), .we(we), .addr(addr), .wdata(wdata),
                   .rdata(r_rdata), .ovf_ev(r_ovf), .cmp_ev(r_cmp), .pwm(r_pwm),
                   .irq(r_irq), .cnt_o(r_cnt));
  initial begin errors = 0; checks = 0; end
  always @(negedge clk) if (rst_n === 1'b1) begin
    checks = checks + 1;
    if (d_rdata !== r_rdata || d_cnt !== r_cnt || d_ovf !== r_ovf || d_cmp !== r_cmp ||
        d_pwm !== r_pwm || d_irq !== r_irq) begin
      errors = errors + 1;
      if (errors <= 10)
        $display("[CHK] MISMATCH t=%0t cs=%b we=%b a=%h wd=%h | rdata %h/%h cnt %h/%h ovf %b/%b cmp %b/%b pwm %b/%b irq %b/%b (dut/ref)",
                 $time, cs, we, addr, wdata, d_rdata, r_rdata, d_cnt, r_cnt,
                 d_ovf, r_ovf, d_cmp, r_cmp, d_pwm, r_pwm, d_irq, r_irq);
    end
  end
endmodule
