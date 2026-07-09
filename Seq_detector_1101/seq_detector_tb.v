`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/07/2026 02:47:55 PM
// Design Name: 
// Module Name: seq_detector_tb
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


module seq_detector_tb;

    logic clk;
    logic rst_n;
    logic din;
    logic dout;
    
    seq_detector_mealy dut (
        .clk(clk),
        .rst_n(rst_n),
        .din(din),
        .dout(dout)
    );

    // Clock generation: 10ns period
    initial clk = 0;
    always #5 clk = ~clk;

    // Test sequence
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
        send_bit(1);   // dout should go high here
        send_bit(0);
        send_bit(0);

        #10;

        // Test 2: overlapping detect -> 1 1 0 1 1 0 1
        send_bit(1);
        send_bit(1);
        send_bit(0);
        send_bit(1);   // first "1101" detected here
        send_bit(1);
        send_bit(0);
        send_bit(1);   // overlapping "1101" detected here again

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
