`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:38:02 11/03/2019 
// Design Name: 
// Module Name:    pipeline_id 
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
module pipeline_id(
	 input clk_i,
	 input reset_i,

    input [31:0] instr_i,
    input [31:0] pc_i,
	 input stall_load_i,
	 
	 input valid_stall_i,
		
    output [4:0] rs1_o,
    output [4:0] rs2_o,
    output [4:0] rd_o,
    output [3:0] alu_op_o,
    output [31:0] imm_o,
    output [5:0] main_opcode_o,
    output [31:0] pc_o,
	 
	 output [3:0] reg_forwarding_type_o,
	 output stall_load_o
    );
	 
// ---------------------------------
// Registers/Wires
// ---------------------------------

	reg [4:0] rs1_o_r;
	reg [4:0] rs2_o_r;
	reg [4:0] rd_o_r;
	reg [3:0] alu_op_o_r;
	reg [31:0] imm_o_r;
	reg [5:0] main_opcode_o_r;
	reg [31:0] pc_o_r;
	reg stall_load_o_r;
	
	reg [3:0] alu_op_w;
	reg [31:0] imm_w;
	reg [5:0] main_opcode_temp_w;
	
	// keeping track of the current rs1, rs2 and rd
	wire [4:0] rs1_w;
	wire [4:0] rs2_w;
	wire [4:0] rd_w;
	
	// required for keeping track of register forwarding
	reg [3:0] reg_forwarding_type_o_r;
	reg [3:0] reg_forwarding_type_w;
	
	reg rs1_rd_yes_w;
	reg rs2_rd_yes_w;
	reg rs1_rd_2_yes_w;
	reg rs2_rd_2_yes_w;
	
	reg [5:0] main_opcode_previous_two_r;
	reg [4:0] rd_previous_two_r;

// ---------------------
// Assigning rs1, rs2 and rd
// ---------------------

	assign rs1_w = instr_i[19:15];
	assign rs2_w = instr_i[24:20];
	assign rd_w  = instr_i[11:7];
	
// ---------------------------------
// whether we need to do register forwarding
// ---------------------------------

	always @(posedge clk_i)
	begin
		if(reset_i)
		begin
			main_opcode_previous_two_r <= 'b0;
			rd_previous_two_r          <= 'b0;
		end
		else
		begin
			if(valid_stall_i)
			begin
				main_opcode_previous_two_r <= main_opcode_previous_two_r;
				rd_previous_two_r          <= rd_previous_two_r;
			end
			else
			begin
				main_opcode_previous_two_r <= main_opcode_o_r;
				rd_previous_two_r          <= rd_o_r;
			end
		end
	end
	
	// to assign the type of register forwarding required
	always @(*)
	begin
		if(stall_load_o_r)
		begin
			if(rd_previous_two_r == rs1_w) // MEM_ONE_RS1
			begin
				reg_forwarding_type_w = 4'b0100;
			end
			else // MEM_ONE_RS2
			begin
				reg_forwarding_type_w = 4'b0101;
			end
		end
		else
		begin
			// to check whether rs1 == the previous rd
			if( (rd_o_r == rs1_w) && (main_opcode_o_r[5] == 1'b0 || main_opcode_o_r[5:3] == 3'b111) && (rd_o_r != 'b0) ) // previous rd == rs1
			begin
				rs1_rd_yes_w = 1'b1;
			end
			else
			begin
				rs1_rd_yes_w = 1'b0;
			end
			// to check whether rs1 == the rd 2 times ago
			if( (rd_previous_two_r == rs1_w) && (main_opcode_previous_two_r[5] == 1'b0 || main_opcode_previous_two_r[5:3] == 3'b111) && (rd_previous_two_r != 'b0) ) // previous 2 rd == rs1
			begin
				rs1_rd_2_yes_w = 1'b1;
			end
			else
			begin
				rs1_rd_2_yes_w = 1'b0;
			end
			// to check whether rs2 == the previous rd
			if( ((instr_i[6:2] == 5'b11000) || (instr_i[6:2] == 5'b01100) || (instr_i[6:2] == 5'b01000)) && (rd_o_r == rs2_w) && (main_opcode_o_r[5] == 1'b0 || main_opcode_o_r[5:3] == 3'b111) && (rd_o_r != 'b0) ) // previous rd == rs2
			begin
				rs2_rd_yes_w = 1'b1;
			end
			else
			begin
				rs2_rd_yes_w = 1'b0;
			end
			// to check whether rs2 == the rd 2 times ago
			if( ((instr_i[6:2] == 5'b11000) || (instr_i[6:2] == 5'b01100) || (instr_i[6:2] == 5'b01000)) && (rd_previous_two_r == rs2_w) && (main_opcode_previous_two_r[5] == 1'b0 || main_opcode_previous_two_r[5:3] == 3'b111) && (rd_previous_two_r != 'b0) ) // previous 2 rd == rs2
			begin
				rs2_rd_2_yes_w = 1'b1;
			end
			else
			begin
				rs2_rd_2_yes_w = 1'b0;
			end		
			// assigning the type of register forwarding for the different cases
			case({rs1_rd_yes_w,rs1_rd_2_yes_w,rs2_rd_yes_w,rs2_rd_2_yes_w})
			4'b0000: reg_forwarding_type_w = 4'b1111; // no register forwarding
			4'b0001: reg_forwarding_type_w = 4'b0011; // ALU_TWO_RS2
			4'b0010: reg_forwarding_type_w = 4'b0001; // ALU_ONE_RS2
			4'b0011: reg_forwarding_type_w = 4'b0001; // ALU_ONE_RS2
			4'b0100: reg_forwarding_type_w = 4'b0010; // ALU_TWO_RS1
			4'b0101: reg_forwarding_type_w = 4'b1001; // ALU_TWO_TWO_RS1_RS2
			4'b0110: reg_forwarding_type_w = 4'b0111; // ALU_ONE_TWO_RS2_RS1
			//4'b0111: reg_forwarding_type_w = 4'b0000; // ALU_
			4'b1000: reg_forwarding_type_w = 4'b0000; // ALU_ONE_RS1
			4'b1001: reg_forwarding_type_w = 4'b0110; // ALU_ONE_TWO_RS1_RS2
			4'b1010: reg_forwarding_type_w = 4'b1000; // ALU_ONE_ONE_RS1_RS2
			//4'b1011: reg_forwarding_type_w = 4'b0000; // ALU_
			4'b1100: reg_forwarding_type_w = 4'b0000; // ALU_ONE_RS1
			//4'b1101: reg_forwarding_type_w = 4'b0000; // ALU_
			//4'b1110: reg_forwarding_type_w = 4'b0000; // ALU_
			4'b1111: reg_forwarding_type_w = 4'b1000; // ALU_ONE_ONE_RS1_RS2
			default: reg_forwarding_type_w = 4'b1111;
			endcase
		end
	end

// ---------------------------------
// Setting the main_opcode
// ---------------------------------

	always @(*)
	begin
		case(instr_i[6:0])
		7'b0000011: // Load
					begin
						case(instr_i[14:12])
							3'b000,3'b001,3'b010,3'b100,3'b101:
								begin
									main_opcode_temp_w = {3'b100,instr_i[14:12]};
								end
							default : main_opcode_temp_w = 6'b001111;
						endcase
					end
		7'b0100011: // Store
					begin
						case(instr_i[14:12])
							3'b000,3'b001,3'b010:
								begin
									main_opcode_temp_w = {3'b101,instr_i[14:12]};
								end
							default : main_opcode_temp_w = 6'b001111;
						endcase
					end
		7'b0010011: // ALU Imm
					begin
						case(instr_i[14:12])
							3'b000,3'b001,3'b010,3'b011,3'b100,3'b101,3'b110,3'b111:
								begin
									main_opcode_temp_w = {2'b01,alu_op_w};
								end
							default : main_opcode_temp_w = 6'b001111;
						endcase
					end
		7'b0110011: // ALU Non Imm or MUL
					begin
						if(instr_i[25]) // Multiplication
							begin
								main_opcode_temp_w = {4'b1111,instr_i[13:12]};
							end
							
						else 
							begin
								case(instr_i[14:12])
									3'b000,3'b001,3'b010,3'b011,3'b100,3'b101,3'b110,3'b111:
										begin
											main_opcode_temp_w = {2'b00,alu_op_w};
										end
									default : main_opcode_temp_w = 6'b001111;
								endcase
							end
					end
		7'b1100011 : // Branch
					begin
						case(instr_i[14:12])
							3'b000,3'b001,3'b100,3'b101,3'b110,3'b111:
								begin
									main_opcode_temp_w = {3'b110,instr_i[14:12]};
								end
							default : main_opcode_temp_w = 6'b001111;
						endcase
					end
		7'b0110111: main_opcode_temp_w = 6'b111000; // LUI
		7'b0010111: main_opcode_temp_w = 6'b111001; // AUIPC
		7'b1101111: main_opcode_temp_w = 6'b111010; // JAL
		7'b1100111: main_opcode_temp_w = 6'b111011; // JALR
		default: main_opcode_temp_w = 6'b001111; // No instruction is like this, denotes error
		endcase
	end

// --------------------------------------------------------
// Setting alu opcode
// --------------------------------------------------------

	always @(*)
	begin
		case(instr_i[6:2])
		5'b00000, // Load and Store and JALR
		5'b01000, // for JALR, need to add rs1 to offset and then jump PC
		5'b11001: alu_op_w = 4'b0000;
		5'b00100, // ALU Immediate and Non Immediate
		5'b01100:
					begin
						alu_op_w[2:0] = instr_i[14:12];
						if( ({instr_i[14:12],instr_i[5]}==4'b0001) || ({instr_i[14:12],instr_i[5]}==4'b1010) || ({instr_i[14:12],instr_i[5]}==4'b1011) )
						begin
							alu_op_w[3] = instr_i[30];
						end
						else
						begin
							alu_op_w[3] = 1'b0;
						end
					end
		5'b11000: // Branch
					begin
						case(instr_i[14:12])
						3'b000: alu_op_w = 4'b1001; // BEQ
						3'b001: alu_op_w = 4'b1010; // BNE
						3'b100: alu_op_w = 4'b1011; // BLT
						3'b101: alu_op_w = 4'b1100; // BGE
						3'b110: alu_op_w = 4'b1110; // BLTU
						3'b111: alu_op_w = 4'b1111; // BGEU
						endcase
					end
		default: alu_op_w = 4'b0000;
		endcase
	end	
	
// ----------------------------------------------
// Assigning the immediate with sign extension
// ----------------------------------------------

	always @(*)
	begin
		case(instr_i[6:2])
		5'b00000: // Load
					begin
						imm_w = {(1<<20)-instr_i[31],instr_i[31:20]};
					end
		5'b01000: // Store
					begin
						imm_w = {(1<<20)-instr_i[31],instr_i[31:25],instr_i[11:7]}; 
					end
		5'b00100: // ALU Immediate
					begin
						imm_w = {(1<<20)-instr_i[31],instr_i[31:20]};
					end
//		5'b01100: // ALU Non Immediate
//					begin
//						ALU non immediate doesn't have any immediate
//					end
		5'b11000: // Branch
					begin
						imm_w = {(1<<19)-instr_i[31],instr_i[31],instr_i[7],instr_i[30:25],instr_i[11:8],1'b0}; 
					end
		5'b01101: imm_w = {instr_i[31:12],12'h000}; // LUI
		5'b00101: imm_w = {instr_i[31:12],12'h000}; // AUIPC
		5'b11011: imm_w = {(1<<11)-instr_i[31],instr_i[31],instr_i[19:12],instr_i[20],instr_i[30:21],1'b0}; // JAL
		5'b11001: imm_w = {(1<<20)-instr_i[31],instr_i[31:20]}; // JALR
		default: imm_w = 'b0;
		endcase
	end
	
// -------------------
// Setting the Output registers
// -------------------

// REG_ID
	always @(posedge clk_i)
	begin
		if(reset_i)
		begin
			rs1_o_r                 <= 'b0; 
			rs2_o_r                 <= 'b0;
			rd_o_r                  <= 'b0;
			alu_op_o_r              <= 'b0;
			imm_o_r                 <= 'b0;
			main_opcode_o_r         <= 'b0;
			pc_o_r                  <= 'b0;
			stall_load_o_r          <= 'b0;
			reg_forwarding_type_o_r <= 'b0;
		end
		else
		begin
			if(valid_stall_i)
			begin
				rs1_o_r                 <= rs1_o_r; 
				rs2_o_r                 <= rs2_o_r;
				rd_o_r                  <= rd_o_r;
				alu_op_o_r              <= alu_op_o_r;
				imm_o_r                 <= imm_o_r;
				main_opcode_o_r         <= main_opcode_o_r;
				pc_o_r                  <= pc_o_r;
				stall_load_o_r          <= stall_load_o_r;
				reg_forwarding_type_o_r <= reg_forwarding_type_o_r;
			end
			else
			begin
				rs1_o_r                 <= rs1_w; 
				rs2_o_r                 <= rs2_w;
				rd_o_r                  <= rd_w;
				alu_op_o_r              <= alu_op_w;
				imm_o_r                 <= imm_w;
				main_opcode_o_r         <= main_opcode_temp_w;
				pc_o_r                  <= pc_i;
				stall_load_o_r          <= stall_load_i;
				reg_forwarding_type_o_r <= reg_forwarding_type_w;
			end
		end
	end
	
	assign rs1_o                 = rs1_o_r; 
	assign rs2_o                 = rs2_o_r;
	assign rd_o                  = rd_o_r;
	assign alu_op_o              = alu_op_o_r;
	assign imm_o                 = imm_o_r;
	assign main_opcode_o         = main_opcode_o_r;
	assign pc_o                  = pc_o_r;
	assign stall_load_o          = stall_load_o_r;
	assign reg_forwarding_type_o = reg_forwarding_type_o_r;

endmodule 