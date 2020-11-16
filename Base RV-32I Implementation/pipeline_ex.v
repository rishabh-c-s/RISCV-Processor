`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    17:47:29 11/03/2019 
// Design Name: 
// Module Name:    pipeline_ex 
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
module pipeline_ex(

	 input clk_i,
	 input reset_i,
	 
	 // comes from ID stage
    input [4:0] rs1_i, 
    input [4:0] rs2_i, 
	 input [4:0] rd_i,
    input [3:0] alu_op_i,
	 input [31:0] imm_i,
	 
    input [31:0] pc_i,
	 input [5:0] main_opcode_i,
	 
	 input stall_load_i,
	 input [3:0] reg_forwarding_type_i,
	 
	 // comes from WB stage
    input [4:0] rd_wb_i,  
	 input [31:0] indata_wb_i,
	 input we_wb_i,
	 
	 // register forwarding input comes from mem stage
	 input [31:0] reg_forwarding_mem_i,
	 
	 // outputs
	 // These go to DMEM stage
    output [31:0] alu_out_o,
    output [31:0] wdata_o, // rv2 value
	 
	 output [4:0] rd_o,
    
	 output [5:0] main_opcode_o,
 
	 // These two go back to the IF stage
	 output [31:0] pc_new_o_wires,
    output if_branch_o_wires,
	 
	 // this will propagate the stall
	 output main_stall_o_register,
	 output [31:0] x31
	 );
	 
// ---------------------------------
// Registers/Wires
// ---------------------------------

	reg [31:0] alu_out_o_r;
	reg [31:0] wdata_o_r;
	reg [4:0] rd_o_r;
	reg [5:0] main_opcode_o_r;
	reg main_stall_o_r;
	
	reg [31:0] reg_forwarding_alu_one_r;
	reg [31:0] reg_forwarding_alu_two_r;
	
	reg  [31:0] alu_in1;
	reg  [31:0] alu_in2_before;
	
	wire [31:0] alu_in2;
	wire [31:0] alu_out;
	
	reg  [31:0] alu_out_main;
	wire [31:0] rv1;
	wire [31:0] rv2;
	
	reg if_previous_branch;
	reg if_previous_two_branch;
	
	wire if_branch_w;
	
// ----------------------------------------------
// Setting whether previous or previous 2 are branches
// ----------------------------------------------	

	always @(posedge clk_i)
	begin
		if(reset_i)
		begin
			if_previous_branch <= 'b0;
			if_previous_two_branch <= 'b0;
		end
		else
		begin
			if_previous_branch <= if_branch_w;
			if_previous_two_branch <= if_previous_branch;
		end
	end

// ----------------------------------------------
// Setting reg_forwarding_alu_one_r and reg_forwarding_alu_two_r
// ----------------------------------------------

	always @(posedge clk_i)
	begin
		if(reset_i)
		begin
			reg_forwarding_alu_one_r <= 'b0;
			reg_forwarding_alu_two_r <= 'b0;
		end	
		else
		begin
			reg_forwarding_alu_two_r <= reg_forwarding_alu_one_r;
			reg_forwarding_alu_one_r <= alu_out_main;
		end
	end
	
// ---------------------------------
// Setting alu input 1 and alu input 2
// ---------------------------------

	always @(*)
	begin
		case(reg_forwarding_type_i)
		4'b0000:
					begin 
						alu_in1        = reg_forwarding_alu_one_r;
						alu_in2_before = rv2;
					end
		4'b0001:
					begin 
						alu_in1        = rv1;
						alu_in2_before = reg_forwarding_alu_one_r;
					end
		4'b0010:
					begin 
						alu_in1        = reg_forwarding_alu_two_r;
						alu_in2_before = rv2;
					end
		4'b0011:
					begin 
						alu_in1        = rv1;
						alu_in2_before = reg_forwarding_alu_two_r;
					end
		4'b0100:
					begin 
						alu_in1        = reg_forwarding_mem_i;
						alu_in2_before = rv2;
					end
		4'b0101:
					begin 
						alu_in1        = rv1;
						alu_in2_before = reg_forwarding_mem_i;
					end
		4'b0110:
					begin 
						alu_in1        = reg_forwarding_alu_one_r;
						alu_in2_before = reg_forwarding_alu_two_r;
					end
		4'b0111:
					begin 
						alu_in1        = reg_forwarding_alu_two_r;
						alu_in2_before = reg_forwarding_alu_one_r;
					end
		4'b1000:
					begin 
						alu_in1        = reg_forwarding_alu_one_r;
						alu_in2_before = reg_forwarding_alu_one_r;
					end
		4'b1001:
					begin 
						alu_in1        = reg_forwarding_alu_two_r;
						alu_in2_before = reg_forwarding_alu_two_r;
					end
		4'b1111:
					begin 
						alu_in1        = rv1;
						alu_in2_before = rv2;
					end
		default: 
					begin 
						alu_in1        = rv1;
						alu_in2_before = rv2;
					end
		endcase
	end

// ---------------------------------
// Setting alu input 2
// ---------------------------------

	assign alu_in2 = (main_opcode_i[5:4] == 2'b00 || main_opcode_i[5:3] == 3'b110) ? alu_in2_before : imm_i;

// -------------------------------------
// Setting if_branch and the branch value wires
// -------------------------------------

// these are the only non-registered outputs from the EX stage
	
	assign if_branch_w = ( (main_opcode_i == 6'b111010 || main_opcode_i == 6'b111011 || (main_opcode_i[5:3] == 3'b110 && alu_out == 'b1)) && (~if_previous_branch) && (~if_previous_two_branch) && (~stall_load_i) ) ? 1'b1 : 1'b0;
	assign pc_new_o_wires = (main_opcode_i == 6'b111011) ? alu_in1 + imm_i : pc_i + imm_i;	
	assign if_branch_o_wires = if_branch_w;

// -------------------
// Setting main output from ALU
// -------------------

	always @(*)
	begin
		if(main_opcode_i[5] == 1'b0)
		begin
			alu_out_main = alu_out;
		end
		else
		begin
			case(main_opcode_i)
			6'b111000: alu_out_main = imm_i;
			6'b111001: alu_out_main = pc_i + imm_i;
			6'b111010, 
			6'b111011: alu_out_main = pc_i + 'd4;
			default: alu_out_main = alu_out;
			endcase
		end
	end

// ---------------------------------
// Assigning output registers
// ---------------------------------

	always @(posedge clk_i)
	begin
		if(reset_i)
		begin
			alu_out_o_r 	 <= 'b0;
			wdata_o_r		 <= 'b0;
			rd_o_r			 <= 'b0;
			main_opcode_o_r <= 'b0;
			main_stall_o_r  <= 'b0;
		end
		else
		begin
			alu_out_o_r 	 <= alu_out_main;
			wdata_o_r		 <= alu_in2_before;
			rd_o_r			 <= rd_i;
			main_opcode_o_r <= main_opcode_i;
			main_stall_o_r  <= (stall_load_i) | (if_previous_branch) | (if_previous_two_branch);
		end
	end
	
	assign alu_out_o  	         = alu_out_o_r;
	assign wdata_o	     	         = wdata_o_r;
	assign rd_o		               = rd_o_r;
	assign main_opcode_o          = main_opcode_o_r;
	assign main_stall_o_register  = main_stall_o_r;

// ---------------------------------
// Instantiate Modules
// ---------------------------------

alu_32_bit alu_main_inst (
    .in1(alu_in1), 
    .in2(alu_in2), 
    .op(alu_op_i), 
    .out(alu_out)
    );
	 
rf rf_module (
    .clk(clk_i), 
    .rs1(rs1_i), 
    .rs2(rs2_i), 
    .rd(rd_wb_i), 
    .we(we_wb_i), 
    .rv1(rv1), 
    .rv2(rv2), 
    .indata(indata_wb_i),
	 .x31(x31)
    );

endmodule 
