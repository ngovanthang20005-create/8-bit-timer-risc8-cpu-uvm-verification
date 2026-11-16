// timer8.v - 8-bit timer core: prescaler + counter + compare + PWM
// Define BUG_OVF / BUG_PWM / BUG_CMP to plant a bug (mutation testing).
module timer8 (
  input  wire       clk,
  input  wire       rst_n,
  input  wire       en,
  input  wire [7:0] presc,
  input  wire [7:0] load,
  input  wire [7:0] cmp,
  output reg  [7:0] cnt,
  output wire       ovf_ev,   // this clock the counter wraps (combinational event)
  output wire       cmp_ev,   // this clock cnt == cmp at a step
  output wire       pwm_out
);
  reg [7:0] pre;
  wire step = en && (pre >= presc);          // time for one counter step

`ifdef BUG_OVF
  assign ovf_ev = step && (cnt >  load);     // BUG: counts one past LOAD
`else
  assign ovf_ev = step && (cnt >= load);
`endif
`ifdef BUG_CMP
  assign cmp_ev = step && (cnt == cmp + 8'd1); // BUG: compare one count late
`else
  assign cmp_ev = step && (cnt == cmp);
`endif
`ifdef BUG_PWM
  assign pwm_out = en && (cnt <= cmp);       // BUG: <= instead of <
`else
  assign pwm_out = en && (cnt < cmp);
`endif

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      pre <= 8'd0;
      cnt <= 8'd0;
    end else if (!en) begin
      pre <= 8'd0;
      cnt <= 8'd0;
    end else if (!step) begin
      pre <= pre + 8'd1;
    end else begin
      pre <= 8'd0;
      cnt <= ovf_ev ? 8'd0 : cnt + 8'd1;
    end
  end
endmodule
