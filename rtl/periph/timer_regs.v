// timer_regs.v - register file, read mux, sticky W1C flags, irq
// Define BUG_ONESHOT / BUG_W1C to plant a bug.
module timer_regs (
  input  wire       clk,
  input  wire       rst_n,
  // one-clock CPU bus
  input  wire       cs,
  input  wire       we,
  input  wire [3:0] addr,
  input  wire [7:0] wdata,
  output reg  [7:0] rdata,
  // to / from timer core
  output wire       en,
  output wire       oneshot,
  output wire [7:0] presc,
  output wire [7:0] load,
  output wire [7:0] cmp,
  input  wire [7:0] cnt,
  input  wire       ovf_ev,
  input  wire       cmp_ev,
  output wire       irq
);
  reg       en_r, os_r;
  reg [7:0] presc_r, load_r, cmp_r;
  reg [1:0] ie_r, st_r;                    // st_r = {CMP, OVF}

  wire wr  = cs & we;
  wire [1:0] clr = (wr && addr == 4'hE) ? wdata[1:0] : 2'b00;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      en_r <= 1'b0; os_r <= 1'b0;
      presc_r <= 8'h00; load_r <= 8'hFF; cmp_r <= 8'h80;
      ie_r <= 2'b00; st_r <= 2'b00;
    end else begin
      if (wr) begin
        case (addr)
          4'h0: begin en_r <= wdata[0]; os_r <= wdata[1]; end
          4'h1: presc_r <= wdata;
          4'h2: load_r  <= wdata;
          4'h3: cmp_r   <= wdata;
          4'hD: ie_r    <= wdata[1:0];
          default: ;
        endcase
      end
`ifndef BUG_ONESHOT
      if (ovf_ev && os_r) en_r <= 1'b0;    // hardware stops the timer (wins over CPU write)
`endif
`ifdef BUG_W1C
      st_r <= (st_r | {cmp_ev, ovf_ev}) & ~clr;   // BUG: CPU clear beats same-clock event
`else
      st_r <= (st_r & ~clr) | {cmp_ev, ovf_ev};   // event wins
`endif
    end
  end

  assign en = en_r;  assign oneshot = os_r;
  assign presc = presc_r; assign load = load_r; assign cmp = cmp_r;
  assign irq = |(st_r & ie_r);

  always @* begin
    rdata = 8'h00;
    if (cs) begin
      case (addr)
        4'h0: rdata = {6'b0, os_r, en_r};
        4'h1: rdata = presc_r;
        4'h2: rdata = load_r;
        4'h3: rdata = cmp_r;
        4'h4: rdata = cnt;
        4'hD: rdata = {6'b0, ie_r};
        4'hE: rdata = {6'b0, st_r};
        4'hF: rdata = 8'h54;               // ID
        default: rdata = 8'h00;
      endcase
    end
  end
endmodule
