`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/07/2026 02:39:23 PM
// Design Name: 
// Module Name: seq_detector_mealy
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

module seq_detector_mealy (
    input  logic clk,
    input  logic rst_n,      // active-low reset
    input  logic din,        // serial input bit
    output logic dout        // high for 1 cycle when "1101" detected
);

    // State encoding
    typedef enum logic [2:0] {
        S0 = 3'b000,
        S1 = 3'b001,
        S2 = 3'b010,
        S3 = 3'b011,
        S4 = 3'b100
    } state_t;

    state_t current_state, next_state;

    // State register (sequential logic)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            current_state <= S0;
        else
            current_state <= next_state;
    end

    // Next-state logic (combinational)
    always_comb begin
        next_state = current_state; // default, avoids latch
        case (current_state)
            S0: next_state = din ? S1 : S0;
            S1: next_state = din ? S2 : S0;
            S2: next_state = din ? S2 : S3;
            S3: next_state = din ? S4 : S0;
            S4: next_state = din ? S2 : S0;
            default: next_state = S0;
        endcase
    end

    always_comb begin
        dout = (current_state == S3) && din; // only high when S3 gets a 1
    end

endmodule
