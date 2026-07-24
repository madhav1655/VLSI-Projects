`timescale 1ns/1ps
module riscp16_tb;
    reg clk;
    reg rst_n;
    wire [11:0] pc_out;
    wire        halted;

    integer errors;
    integer i;

    riscp16_top dut (
        .clk(clk), .rst_n(rst_n),
        .pc_out(pc_out), .halted(halted)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    task check16; input [15:0] actual; input [15:0] expected; input [8*32:1] msg; begin
        if (actual !== expected) begin
            $display("*** CHECK FAILED: %s (expected %0d, got %0d) ***", msg, expected, actual);
            errors = errors + 1;
        end else begin
            $display(" CHECK PASSED: %s = %0d", msg, actual);
        end
    end endtask

    initial begin
        errors = 0;

        // ---- Preload instruction memory with the test program ----
        // addr0:  ADDI R1, R0, 5
        dut.imem[0]  = 16'h4045;
        // addr1:  ADDI R2, R0, 3
        dut.imem[1]  = 16'h4083;
        // addr2:  ADD  R3, R1, R2
        dut.imem[2]  = 16'h0298;
        // addr3:  SUB  R4, R1, R2
        dut.imem[3]  = 16'h12A0;
        // addr4:  AND  R5, R1, R2
        dut.imem[4]  = 16'h22A8;
        // addr5:  OR   R6, R1, R2
        dut.imem[5]  = 16'h32B0;
        // addr6:  STORE [R0+10], R3
        dut.imem[6]  = 16'h60CA;
        // addr7:  LOAD  R7, R0, 10
        dut.imem[7]  = 16'h51CA;
        // addr8:  BEQ   R3, R7, 2        (R3==R7 -> PC = PC+1+2 = 11)
        dut.imem[8]  = 16'h77C2;
        // addr9:  ADDI R1, R0, 9         (must be skipped by the branch)
        dut.imem[9]  = 16'h4049;
        // addr10: ADDI R1, R0, 10        (must be skipped by the branch)
        dut.imem[10] = 16'h404A;
        // addr11: JMP 13
        dut.imem[11] = 16'h800D;
        // addr12: ADDI R1, R0, 11        (dead code, must be skipped by the jump)
        dut.imem[12] = 16'h404B;
        // addr13: HALT
        dut.imem[13] = 16'hF000;

        // ---- Reset ----
        rst_n = 0;
        #12;
        rst_n = 1;

        // ---- Run until the processor halts (or a safety timeout) ----
        for (i = 0; i < 100 && !halted; i = i + 1) begin
            @(posedge clk);
            $display("t=%0t  PC=%0d  instr=0x%04h  halted=%b", $time, pc_out, dut.instr, halted);
        end
        #10;

        // ---- Self-check final architectural state against the expected trace ----
        check16(dut.rf.regs[1], 16'd5, "R1 (ADDI result)");
        check16(dut.rf.regs[2], 16'd3, "R2 (ADDI result)");
        check16(dut.rf.regs[3], 16'd8, "R3 (ADD result)");
        check16(dut.rf.regs[4], 16'd2, "R4 (SUB result)");
        check16(dut.rf.regs[5], 16'd1, "R5 (AND result)");
        check16(dut.rf.regs[6], 16'd7, "R6 (OR result)");
        check16(dut.rf.regs[7], 16'd8, "R7 (LOAD result)");
        check16(dut.dmem[10],   16'd8, "DMEM[10] (STORE result)");
        check16({4'b0,pc_out}, 16'd13, "final PC (post JMP)");
        check16({15'b0,halted}, 16'd1, "halted flag");

        if (errors == 0)
            $display("\nALL CHECKS PASSED. Simulation complete.");
        else
            $display("\n%0d CHECK(S) FAILED. Simulation complete.", errors);

        $finish;
    end
endmodule
