// timer_ref.v - cycle-accurate reference model (testbench only), blocking-style
module timer_ref (
  input  wire       clk, rst_n, cs, we,
  input  wire [3:0] addr,
  input  wire [7:0] wdata,
  output reg  [7:0] rdata,
  output wire       ovf_ev, cmp_ev, pwm, irq,
  output wire [7:0] cnt_o
);
  reg       en, os;
  reg [7:0] presc, load, cmp, cnt, pre;
  reg [1:0] ie, st;
  reg       d_step, d_ovf, d_cmp, os_before;
  reg [1:0] clr;

  wire step = en && (pre >= presc);
  assign ovf_ev = step && (cnt >= load);
  assign cmp_ev = step && (cnt == cmp);
  assign pwm    = en && (cnt < cmp);
  assign irq    = |(st & ie);
  assign cnt_o  = cnt;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      en = 0; os = 0; presc = 0; load = 8'hFF; cmp = 8'h80;
      cnt = 0; pre = 0; ie = 0; st = 0;
    end else begin
      d_step    = en && (pre >= presc);
      d_ovf     = d_step && (cnt >= load);
      d_cmp     = d_step && (cnt == cmp);
      os_before = os;
      clr       = (cs && we && addr == 4'hE) ? wdata[1:0] : 2'b00;
      // timer core (old configuration)
      if (!en)          begin pre = 0; cnt = 0; end
      else if (!d_step) pre = pre + 1;
      else begin pre = 0; cnt = d_ovf ? 8'd0 : cnt + 1; end
      // registers
      if (cs && we) begin
        if (addr == 4'h0) begin en = wdata[0]; os = wdata[1]; end
        if (addr == 4'h1) presc = wdata;
        if (addr == 4'h2) load  = wdata;
        if (addr == 4'h3) cmp   = wdata;
        if (addr == 4'hD) ie    = wdata[1:0];
      end
      if (d_ovf && os_before) en = 0;
      st = (st & ~clr) | {d_cmp, d_ovf};
    end
  end

  always @* begin
    rdata = 8'h00;
    if (cs) begin
      case (addr)
        4'h0: rdata = {6'b0, os, en};
        4'h1: rdata = presc;
        4'h2: rdata = load;
        4'h3: rdata = cmp;
        4'h4: rdata = cnt;
        4'hD: rdata = {6'b0, ie};
        4'hE: rdata = {6'b0, st};
        4'hF: rdata = 8'h54;
        default: rdata = 8'h00;
      endcase
    end
  end
endmodule
