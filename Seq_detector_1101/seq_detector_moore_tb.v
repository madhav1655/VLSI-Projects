`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/07/2026 03:14:28 PM
// Design Name: 
// Module Name: seq_detector_moore_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module seq_detector_moore_tb;

    logic clk;
    logic rst_n;
    logic din;
    logic dout;

    // Instantiate DUT
    seq_detector_moore dut (
        .clk(clk),
        .rst_n(rst_n),
        .din(din),
        .dout(dout)
    );

    // Clock generation: 10ns period
    initial clk = 0;
    always #5 clk = ~clk;

    // Test sequence - same as Mealy version, for direct comparison
    initial begin
        $display("Time\tdin\tdout");
        $monitor("%0t\t%b\t%b", $time, din, dout);

        rst_n = 0;
        din   = 0;
        #12;
        rst_n = 1;

        // Test 1: normal detect -> stream contains 1101
        send_bit(0);
        send_bit(1);
        send_bit(1);
        send_bit(0);
        send_bit(1);   // match completes here -> dout high on NEXT cycle
        send_bit(0);
        send_bit(0);

        #10;

        // Test 2: overlapping detect -> 1 1 0 1 1 0 1
        send_bit(1);
        send_bit(1);
        send_bit(0);
        send_bit(1);   // first match
        send_bit(1);
        send_bit(0);
        send_bit(1);   // overlapping second match

        #10;

        // Test 3: reset in the middle of a partial match
        send_bit(1);
        send_bit(1);
        send_bit(0);
        rst_n = 0;      // reset while mid-sequence
        #10;
        rst_n = 1;
        send_bit(1);
        send_bit(1);
        send_bit(0);
        send_bit(1);   // should still detect correctly after reset

        #20;
        $display("Simulation complete.");
        $finish;
    end

    // Task to apply one bit for one clock cycle
    task send_bit(input logic b);
        din = b;
        @(posedge clk);
    endtask

endmodule
