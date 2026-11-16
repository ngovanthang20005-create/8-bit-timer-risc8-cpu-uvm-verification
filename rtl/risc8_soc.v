// =====================================================================
//  FILE   : rtl/risc8_soc.v
//  CPU RISC-8 5-stage + Timer, memory-mapped at 0xF0..0xFF
// =====================================================================
`timescale 1ns/1ps
module risc8_soc #(
    parameter IMEM_FILE = "C:/Users/ngova/Downloads/risc8_soc_final/risc8_soc/timer_demo.hex"
) (
    input  wire       clk,
    input  wire       rst,        // active high (CPU convention)
    output wire       halted,
    output wire [7:0] pc_out,
    output wire       irq,        // timer interrupt pin (CPU polls IRQ_STAT)
    output wire       pwm_out
);
    wire       io_cs, io_we;
    wire [3:0] io_addr;
    wire [7:0] io_wdata, io_rdata;

    /* verilator lint_off PINCONNECTEMPTY */
    risc8_5stage_core #(.IMEM_FILE(IMEM_FILE), .IO_ENABLE(1), .IO_PAGE(4'hF)) u_cpu (
        .clk(clk), .rst(rst), .halted(halted), .pc_out(pc_out),
        .flags_out(), .instr_done(),
        .io_cs(io_cs), .io_we(io_we), .io_addr(io_addr),
        .io_wdata(io_wdata), .io_rdata(io_rdata)
    );

    /* verilator lint_on PINCONNECTEMPTY */

    /* verilator lint_off PINCONNECTEMPTY */
    timer_top u_timer (
        .clk(clk), .rst_n(~rst),          // polarity conversion
        .cs(io_cs), .we(io_we), .addr(io_addr), .wdata(io_wdata), .rdata(io_rdata),
        .irq(irq), .pwm_out(pwm_out),
        .ovf_ev(), .cmp_ev(), .cnt()
    );
    /* verilator lint_on PINCONNECTEMPTY */
endmodule
