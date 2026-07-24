`timescale 1ns/1ps
module register_file (
    input        clk,
    input        rst_n,
    input        reg_write,
    input  [2:0] rs_addr,
    input  [2:0] rt_addr,
    input  [2:0] write_addr,
    input  [15:0] write_data,
    output [15:0] rs_data,
    output [15:0] rt_data
);
    reg [15:0] regs [0:7];
    integer i;

    assign rs_data = regs[rs_addr];
    assign rt_data = regs[rt_addr];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 8; i = i + 1)
                regs[i] <= 16'h0000;
        end else if (reg_write) begin
            regs[write_addr] <= write_data;
        end
    end
endmodule
