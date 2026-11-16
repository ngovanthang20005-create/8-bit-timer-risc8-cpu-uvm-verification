`timescale 1ns/1ps
// tb_dump.v - runs program.hex to HLT and writes dump.txt for sw/random_test.py
//   dump.txt: R0..R7 (hex) | Z | C | MEM[0..255] (hex), whitespace separated
module tb_dump;
    reg clk = 0, rst = 1;
    wire halted, instr_done; wire [7:0] pc; wire [1:0] flags;
    risc8_5stage_core #(.IMEM_FILE("program.hex")) dut (
        .clk(clk), .rst(rst), .halted(halted), .pc_out(pc), .flags_out(flags),
        .instr_done(instr_done),
        .io_cs(), .io_we(), .io_addr(), .io_wdata(), .io_rdata(8'h00)   // I/O port tied off
    );
    initial forever #5 clk = ~clk;
    integer i, f;
    initial begin
        #22 rst = 0;
        wait (halted);
        @(posedge clk); @(posedge clk);
        f = $fopen("dump.txt", "w");
        for (i = 0; i < 8; i = i + 1) $fwrite(f, "%02h ", dut.u_rf.r[i]);
        $fwrite(f, "%0d %0d ", flags[1], flags[0]);
        for (i = 0; i < 256; i = i + 1) $fwrite(f, "%02h ", dut.u_dmem.mem[i]);
        $fclose(f);
        $finish;
    end
    initial begin #200000 $finish; end
endmodule
