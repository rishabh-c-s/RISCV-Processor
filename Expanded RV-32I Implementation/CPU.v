`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:40:23 11/09/2019 
// Design Name: 
// Module Name:    CPU 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module CPU(
		input clk_i,
		input reset_i,
		
		output [31:0] pc,
		output [31:0] x31,
		output [31:0] x3
    );

		wire [31:0] pc_new_ex_w;
		wire if_branch_ex_w;
		wire main_stall_ex_w;
		
		wire [31:0] instr_if_w;
		wire [31:0] pc_if_w;
		wire stall_load_if_w;

		wire [4:0] rs1_id_w;
		wire [4:0] rs2_id_w;
		wire [4:0] rd_id_w;
		wire [3:0] alu_op_id_w;
		wire [31:0] imm_id_w;
		wire [5:0] main_opcode_id_w;
		wire [31:0] pc_id_w;
		wire [3:0] reg_forwarding_type_id_w;
		wire stall_load_id_w;
		wire [31:0] alu_out_ex_w;
		wire [4:0] rd_ex_w;
		wire [5:0] main_opcode_ex_w;
		wire [31:0] dmem_out_mem_w;
		wire [5:0] opcode_mem_w;
		wire [31:0] alu_out_mem_w;
		wire stall_mem_w;
		wire [4:0] rd_wb_w;
		wire [31:0] indata_wb_w;
		wire [31:0] wdata_ex_w;
		wire we_wb_w;
		wire [4:0] rd_mem_w;
		
		wire valid_stall_mem_w;
		wire [31:0] dmem_out_wb_w;
		wire [31:0] dmem_read_mem_w;
		wire [31:0] peripheral_read_mem_w;
		
		wire [31:0] mul_read_mem_w;
		wire [31:0] mul_in_ex_w;
		
		assign pc = pc_if_w;
		wire [31:0] x4, x10;

pipeline_if IF_STAGE (
    .clk_i(clk_i), 
    .reset_i(reset_i), 
    .pc_new_i(pc_new_ex_w), 
    .if_branch_i(if_branch_ex_w), 
	 .valid_stall_i(valid_stall_mem_w),
    .instr_o(instr_if_w), 
    .pc_o(pc_if_w), 
    .stall_load_o(stall_load_if_w)
    );
	 
pipeline_id ID_STAGE (
    .clk_i(clk_i), 
    .reset_i(reset_i), 
    .instr_i(instr_if_w), 
    .pc_i(pc_if_w), 
    .stall_load_i(stall_load_if_w), 
	 .valid_stall_i(valid_stall_mem_w),
    .rs1_o(rs1_id_w), 
    .rs2_o(rs2_id_w), 
    .rd_o(rd_id_w), 
    .alu_op_o(alu_op_id_w), 
    .imm_o(imm_id_w), 
    .main_opcode_o(main_opcode_id_w), 
    .pc_o(pc_id_w), 
    .reg_forwarding_type_o(reg_forwarding_type_id_w), 
    .stall_load_o(stall_load_id_w)
    );
	 
pipeline_ex EX_STAGE (
    .clk_i(clk_i), 
    .reset_i(reset_i), 
    .rs1_i(rs1_id_w), 
    .rs2_i(rs2_id_w), 
    .rd_i(rd_id_w), 
    .alu_op_i(alu_op_id_w), 
    .imm_i(imm_id_w), 
    .pc_i(pc_id_w), 
    .main_opcode_i(main_opcode_id_w), 
    .reg_forwarding_type_i(reg_forwarding_type_id_w), 
	 
	 .stall_load_i(stall_load_id_w),
    
	 .rd_wb_i(rd_wb_w), 
    .indata_wb_i(indata_wb_w), 
    .we_wb_i(we_wb_w), 
	 
    .reg_forwarding_mem_i(dmem_out_wb_w), 
	 
	 .valid_stall_i(valid_stall_mem_w),
	 	 
    .alu_out_o(alu_out_ex_w), 
    .wdata_o(wdata_ex_w), 
	 .mul_in1_o(mul_in_ex_w),
    .rd_o(rd_ex_w), 
    .main_opcode_o(main_opcode_ex_w), 
	 
    .pc_new_o_wires(pc_new_ex_w), 
    .if_branch_o_wires(if_branch_ex_w),
	 
	 .main_stall_o_register(main_stall_ex_w),
	 .x31(x31),
	 .x3(x3),
	 .x4(x4),
	 .x10(x10)
    );

pipeline_mem MEM_STAGE (
    .clk(clk_i), 
    .reset(reset_i), 
    .alu_out_i(alu_out_ex_w), 
    .dmem_data_i(wdata_ex_w), 
	 .mul_in1_i(mul_in_ex_w),
	 
    .opcode_i(main_opcode_ex_w), 
    .rd_i(rd_ex_w), 
    .stall_i(main_stall_ex_w), 
	 
	 .valid_stall_i(valid_stall_mem_w),
			
	 .dmem_read_o(dmem_read_mem_w),
	 .peripheral_read_o(peripheral_read_mem_w),
    .opcode_o(opcode_mem_w), 
    .alu_out_o(alu_out_mem_w), 
    .rd_o(rd_mem_w), 
    .stall_o(stall_mem_w),
	 .valid_stall_o(valid_stall_mem_w),
	 
	 .mul_read_o(mul_read_mem_w)
    );

pipeline_wb WB_STAGE (
	 .dmem_read_i(dmem_read_mem_w),
	 .peripheral_read_i(peripheral_read_mem_w),
    .opcode_i(opcode_mem_w), 
    .rd_i(rd_mem_w), 
    .alu_out_i(alu_out_mem_w), 
    .stall_i(stall_mem_w), 
	 .mul_read_i(mul_read_mem_w),
	 
    .reg_data_o(indata_wb_w), 
    .reg_we_o(we_wb_w), 
    .rd_o(rd_wb_w),
	 .dmem_out_o(dmem_out_wb_w)
    );

endmodule 