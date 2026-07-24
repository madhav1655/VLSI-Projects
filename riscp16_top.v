`timescale 1ns/1ps
module riscp16_top (
    input  clk,
    input  rst_n,
    output [11:0] pc_out,   // exposed for observability in simulation
    output        halted
);
    // ---------------- Instruction fetch ----------------
    reg  [11:0] pc;
    wire [11:0] pc_next;
    reg  [15:0] imem [0:4095];   // instruction memory, preloaded by the testbench
    wire [15:0] instr = imem[pc];

    // ---------------- Instruction fields ----------------
    wire [3:0] opcode      = instr[15:12];
    wire [2:0] rs_addr     = instr[11:9];
    wire [2:0] rt_addr     = instr[8:6];   // R-type "rt", and I-type dest/src/compare reg (same bit slot)
    wire [2:0] rd_addr_r   = instr[5:3];   // R-type destination only
    wire [5:0] imm6        = instr[5:0];
    wire [11:0] jaddr      = instr[11:0];

    wire [15:0] imm_ext16  = {{10{imm6[5]}}, imm6};   // sign-extend to 16 bits (ALU operand)
    wire [11:0] imm_ext12  = {{6{imm6[5]}},  imm6};   // sign-extend to 12 bits (branch offset)

    // ---------------- Control unit ----------------
    wire reg_write, mem_read, mem_write, alu_src, branch, jump, halt, mem_to_reg;
    wire [1:0] alu_op;
    control_unit cu (
        .opcode(opcode), .reg_write(reg_write), .mem_read(mem_read),
        .mem_write(mem_write), .alu_src(alu_src), .branch(branch),
        .jump(jump), .halt(halt), .mem_to_reg(mem_to_reg), .alu_op(alu_op)
    );

    // R-type instructions (ADD/SUB/AND/OR) write to instr[5:3];
    // I-type instructions (ADDI/LOAD) write to instr[8:6].
    wire is_r_type = (opcode == 4'b0000) || (opcode == 4'b0001) ||
                      (opcode == 4'b0010) || (opcode == 4'b0011);
    wire [2:0] write_addr = is_r_type ? rd_addr_r : rt_addr;

    // ---------------- Register file ----------------
    wire [15:0] rs_data, rt_data;
    wire [15:0] write_back_data;
    register_file rf (
        .clk(clk), .rst_n(rst_n), .reg_write(reg_write),
        .rs_addr(rs_addr), .rt_addr(rt_addr), .write_addr(write_addr),
        .write_data(write_back_data),
        .rs_data(rs_data), .rt_data(rt_data)
    );

    // ---------------- ALU ----------------
    wire [15:0] alu_b = alu_src ? imm_ext16 : rt_data;
    wire [15:0] alu_result;
    alu alu_inst (
        .a(rs_data), .b(alu_b), .alu_op(alu_op), .result(alu_result)
    );

    // ---------------- Data memory ----------------
    // 256 x 16-bit, addressed by the lower 8 bits of the computed address
    reg  [15:0] dmem [0:255];
    wire [7:0]  dmem_addr  = alu_result[7:0];
    wire [15:0] dmem_rdata = dmem[dmem_addr];

    // STORE writes the register in the "rt" bit-slot (instr[8:6]) to memory
    always @(posedge clk) begin
        if (mem_write)
            dmem[dmem_addr] <= rt_data;
    end

    assign write_back_data = mem_to_reg ? dmem_rdata : alu_result;

    // ---------------- Branch / jump / halt resolution ----------------
    wire        branch_taken = branch && (rs_data == rt_data);
    wire [11:0] pc_plus1     = pc + 12'd1;
    wire [11:0] branch_target= pc_plus1 + imm_ext12;

    assign pc_next = halt         ? pc :
                     jump         ? jaddr :
                     branch_taken ? branch_target :
                                    pc_plus1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) pc <= 12'd0;
        else        pc <= pc_next;
    end

    assign pc_out = pc;
    assign halted = halt;
endmodule
