`timescale 1ns/1ps
module tb_top;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import timer_pkg::*;

  logic clk = 0, rst_n = 0;
  always #5 clk = ~clk;
  initial begin repeat (4) @(posedge clk); #1 rst_n = 1; end

  bus_if bif (.clk(clk), .rst_n(rst_n));
  wire [7:0] d_cnt;

  timer_top dut (.clk(clk), .rst_n(rst_n), .cs(bif.cs), .we(bif.we), .addr(bif.addr),
                 .wdata(bif.wdata), .rdata(bif.rdata), .irq(bif.irq), .pwm_out(bif.pwm_out),
                 .ovf_ev(bif.ovf_ev), .cmp_ev(bif.cmp_ev), .cnt(d_cnt));

  timer_checker chk (.clk(clk), .rst_n(rst_n), .cs(bif.cs), .we(bif.we), .addr(bif.addr),
                     .wdata(bif.wdata), .d_rdata(bif.rdata), .d_cnt(d_cnt), .d_ovf(bif.ovf_ev),
                     .d_cmp(bif.cmp_ev), .d_pwm(bif.pwm_out), .d_irq(bif.irq),
                     .errors(bif.chk_errors), .checks(bif.chk_checks));

  initial begin
    uvm_config_db#(virtual bus_if)::set(null, "*", "vif", bif);
    run_test();
  end
  initial if ($test$plusargs("DUMP")) begin $dumpfile("tb_top.vcd"); $dumpvars(0, tb_top); end
endmodule
