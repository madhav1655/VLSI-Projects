`timescale 1ns/1ps
module alu (
    input  [15:0] a,
    input  [15:0] b,
    input  [1:0]  alu_op,     // 00=ADD, 01=SUB, 10=AND, 11=OR
    output reg [15:0] result
);
    always @(*) begin
        case (alu_op)
            2'b00: result = a + b;
            2'b01: result = a - b;
            2'b10: result = a & b;
            2'b11: result = a | b;
            default: result = 16'h0000;
        endcase
    end
endmodule
