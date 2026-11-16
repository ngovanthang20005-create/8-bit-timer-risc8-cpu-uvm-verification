`timescale 1ns/1ps
interface bus_if (input logic clk, input logic rst_n);
  logic       cs, we;
  logic [3:0] addr;
  logic [7:0] wdata, rdata;
  logic       irq, pwm_out, ovf_ev, cmp_ev;
  logic [31:0] chk_errors, chk_checks;     // from timer_checker

  clocking drv_cb @(posedge clk);
    default input #1step output #1;
    output cs, we, addr, wdata;
    input  rdata;
  endclocking

  clocking mon_cb @(posedge clk);
    default input #1step;
    input cs, we, addr, wdata, rdata, irq, pwm_out, ovf_ev, cmp_ev;
  endclocking
endinterface
