`timescale 1ns/1ps
module control_unit (
    input  [3:0] opcode,
    output reg reg_write,
    output reg mem_read,
    output reg mem_write,
    output reg alu_src,      // 0 = second ALU operand is rt, 1 = sign-extended immediate
    output reg branch,
    output reg jump,
    output reg halt,
    output reg mem_to_reg,   // 1 = write-back value comes from data memory (LOAD)
    output reg [1:0] alu_op
);
    // Opcode map
    localparam ADD   = 4'b0000;
    localparam SUB   = 4'b0001;
    localparam AND_OP= 4'b0010;
    localparam OR_OP = 4'b0011;
    localparam ADDI  = 4'b0100;
    localparam LOAD  = 4'b0101;
    localparam STORE = 4'b0110;
    localparam BEQ   = 4'b0111;
    localparam JMP   = 4'b1000;
    localparam HALT  = 4'b1111;

    always @(*) begin
        // Safe defaults every cycle (avoids unintended latches)
        reg_write   = 1'b0;
        mem_read    = 1'b0;
        mem_write   = 1'b0;
        alu_src     = 1'b0;
        branch      = 1'b0;
        jump        = 1'b0;
        halt        = 1'b0;
        mem_to_reg  = 1'b0;
        alu_op      = 2'b00;

        case (opcode)
            ADD:    begin reg_write = 1'b1; alu_op = 2'b00; end
            SUB:    begin reg_write = 1'b1; alu_op = 2'b01; end
            AND_OP: begin reg_write = 1'b1; alu_op = 2'b10; end
            OR_OP:  begin reg_write = 1'b1; alu_op = 2'b11; end
            ADDI:   begin reg_write = 1'b1; alu_src = 1'b1; alu_op = 2'b00; end
            LOAD:   begin reg_write = 1'b1; alu_src = 1'b1; alu_op = 2'b00;
                           mem_read = 1'b1; mem_to_reg = 1'b1; end
            STORE:  begin alu_src = 1'b1; alu_op = 2'b00; mem_write = 1'b1; end
            BEQ:    begin branch = 1'b1; end
            JMP:    begin jump = 1'b1; end
            HALT:   begin halt = 1'b1; end
            default: ; // treated as NOP
        endcase
    end
endmodule
