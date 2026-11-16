`timescale 1ns/1ps
// tb_risc8_soc.v - system testbench: CPU + Timer running sw/timer_demo.s
// Checks RAM results, the irq pin, the PWM duty and (every clock) the timer against its reference model.
module tb_risc8_soc;
    reg clk = 0, rst = 1;
    wire halted, irq, pwm_out;
    wire [7:0] pc_out;

    risc8_soc #(.IMEM_FILE("timer_demo.hex")) dut (
        .clk(clk), .rst(rst), .halted(halted), .pc_out(pc_out), .irq(irq), .pwm_out(pwm_out));

    initial forever #5 clk = ~clk;

    // reference-model checker watching the real bus between CPU and timer
    wire [31:0] chk_errors, chk_checks;
    timer_checker chk (
        .clk(clk), .rst_n(~rst),
        .cs(dut.io_cs), .we(dut.io_we), .addr(dut.io_addr), .wdata(dut.io_wdata),
        .d_rdata(dut.io_rdata), .d_cnt(dut.u_timer.cnt),
        .d_ovf(dut.u_timer.ovf_ev), .d_cmp(dut.u_timer.cmp_ev),
        .d_pwm(pwm_out), .d_irq(irq), .errors(chk_errors), .checks(chk_checks));

    integer fails = 0, cycles = 0, io_acc = 0, hi = 0, tot = 0, io_viol = 0, k;
    reg irq_seen = 0;
    always @(posedge clk) if (!rst) begin
        if (dut.io_cs) io_acc = io_acc + 1;
        // io_cs may only be high for a real LD/ST while the CPU is running
        if (dut.io_cs && (!(dut.u_cpu.exmem_mem_we || dut.u_cpu.exmem_mem_to_reg) || halted))
            io_viol = io_viol + 1;
        if (irq) irq_seen = 1;
    end

    task chk_mem(input [7:0] a, input [7:0] exp, input [255:0] what);
        begin
            if (dut.u_cpu.u_dmem.mem[a] !== exp) begin
                fails = fails + 1;
                $display("FAIL MEM[%h] = %h expected %h (%0s)", a, dut.u_cpu.u_dmem.mem[a], exp, what);
            end else $display("PASS MEM[%h] = %h (%0s)", a, exp, what);
        end
    endtask

    initial begin
        $dumpfile("risc8_soc.vcd"); $dumpvars(0, tb_risc8_soc);
        repeat (3) @(posedge clk); #1 rst = 0;
        while (!halted && cycles < 20000) begin @(posedge clk); cycles = cycles + 1; end
        if (!halted) begin fails = fails + 1; $display("FAIL CPU did not halt"); end
        $display("CPU halted after %0d cycles, %0d I/O accesses", cycles, io_acc);
        repeat (3) @(posedge clk);
        chk_mem(8'h80, 8'h54, "ID register");
        chk_mem(8'h81, 8'h01, "B: first OVF seen by polling");
        chk_mem(8'h82, 8'h01, "B: second OVF seen by polling");
        chk_mem(8'h83, 8'h02, "C: one-shot cleared EN by itself");
        chk_mem(8'h84, 8'h01, "C: IRQ_STAT = OVF only");
        chk_mem(8'h85, 8'h01, "D: flag set while IRQ_EN=1");
        chk_mem(8'h86, 8'h00, "D: flag cleared by W1C");
        if (dut.u_cpu.u_rf.r[4] !== 8'hE8) begin fails = fails + 1; $display("FAIL R4 = %h expected E8", dut.u_cpu.u_rf.r[4]); end
        else $display("PASS R4 = E8 (ALU op on I/O pointer)");
        if (io_viol != 0) begin fails = fails + 1; $display("FAIL io_cs high %0d clocks without LD/ST", io_viol); end
        else $display("PASS io_cs only for LD/ST");
        for (k = 8'hF0; k <= 8'hFF; k = k + 1)
            if (dut.u_cpu.u_dmem.mem[k] !== 8'h00) begin fails = fails + 1; $display("FAIL RAM[%h] written by an I/O store", k); end
        $display("PASS RAM page F untouched (checked)");
        if (!irq_seen) begin fails = fails + 1; $display("FAIL irq pin never went high"); end
        else $display("PASS irq pin went high during part D");
        if (irq) begin fails = fails + 1; $display("FAIL irq still high at end"); end
        repeat (100) begin @(posedge clk); tot = tot + 1; if (pwm_out) hi = hi + 1; end
        if (hi !== 30) begin fails = fails + 1; $display("FAIL PWM high %0d of %0d (expected 30)", hi, tot); end
        else $display("PASS PWM high 30 of 100 clocks");
        $display("checker: %0d checks, %0d mismatches vs reference model", chk_checks, chk_errors);
        if (fails == 0 && chk_errors == 0) $display("*** SOC TEST PASSED ***");
        else $display("*** SOC TEST FAILED (%0d fails, %0d checker errors) ***", fails, chk_errors);
        $finish;
    end
    initial begin #2_000_000; $display("*** TIMEOUT ***"); $finish; end
endmodule
