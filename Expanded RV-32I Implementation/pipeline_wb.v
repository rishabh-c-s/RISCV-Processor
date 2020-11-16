`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:33:46 11/09/2019 
// Design Name: 
// Module Name:    pipeline_wb 
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
module pipeline_wb(

	//Input
	
	input [5:0] opcode_i,
	input [4:0] rd_i,
	input [31:0] alu_out_i,
	input stall_i,
	
	input [31:0] peripheral_read_i,
	input [31:0] dmem_read_i,
	input [31:0] mul_read_i,
		
	//Output
	
	output [31:0] reg_data_o,
	output reg_we_o,
	output [4:0] rd_o,
	output [31:0] dmem_out_o
);


	reg reg_we_w;
	reg [31:0] reg_data_r;
	
	wire [31:0] rf_write_out;				//Register Write Out
	reg  [31:0] dmem_read_w_local;
	
	//----------------------------------//
	//			Register Input Decoder		//
	//----------------------------------//
	
	always@(*) begin
		case(opcode_i[5])
			//ALU Operations
			1'b0:
				begin
					reg_data_r = alu_out_i;
					reg_we_w  = 'b1;
				end
			//Other Operations
			1'b1:
				begin
					case(opcode_i[4:3])
						//Branch and Store
						2'b10,2'b01:
							begin
								reg_data_r = 'b0;
								reg_we_w  = 'b0;
							end
						//Jump, AUIPC, LUI
						2'b11:
							begin
								if(opcode_i[2] == 1) 
									begin
										reg_data_r = mul_read_i;
										reg_we_w = 'b1;
									end
								else
									begin
										reg_data_r = alu_out_i;
										reg_we_w = 'b1;
									end
							end
						//Load
						2'b00:
							begin
								reg_data_r = dmem_read_w_local;
								reg_we_w = 'b1;	
							end
					endcase
				end
		endcase
	end



	assign rf_write_out = (alu_out_i >= 'd512) ? peripheral_read_i : dmem_read_i ;
	// Setting correct data read from DMEM
	always @(*)
	begin
		case(opcode_i[2:0])
		3'b000:
				begin
					case(alu_out_i[1:0])
					2'b00: dmem_read_w_local = {(1<<24)-rf_write_out[7],rf_write_out[7:0]};
					2'b01: dmem_read_w_local = {(1<<24)-rf_write_out[15],rf_write_out[15:8]};
					2'b10: dmem_read_w_local = {(1<<24)-rf_write_out[23],rf_write_out[23:16]};
					2'b11: dmem_read_w_local = {(1<<24)-rf_write_out[31],rf_write_out[31:24]};
					default: dmem_read_w_local = 'b0;
					endcase
				end
		3'b001:
				begin
					case(alu_out_i[1:0])
					2'b00: dmem_read_w_local = {(1<<16)-rf_write_out[15],rf_write_out[15:0]};
					2'b10: dmem_read_w_local = {(1<<16)-rf_write_out[31],rf_write_out[31:16]};
					default: dmem_read_w_local = 'b0;
					endcase
				end
		3'b010: dmem_read_w_local = rf_write_out;
		3'b100:
				begin
					case(alu_out_i[1:0])
					2'b00: dmem_read_w_local = {24'b0,rf_write_out[7:0]};
					2'b01: dmem_read_w_local = {24'b0,rf_write_out[15:8]};
					2'b10: dmem_read_w_local = {24'b0,rf_write_out[23:16]};
					2'b11: dmem_read_w_local = {24'b0,rf_write_out[31:24]};
					default: dmem_read_w_local = 'b0;
					endcase
				end
		3'b101:
				begin
					case(alu_out_i[1:0])
					2'b00: dmem_read_w_local = {16'b0,rf_write_out[15:0]};
					2'b10: dmem_read_w_local = {16'b0,rf_write_out[31:16]};
					default: dmem_read_w_local = 'b0;
					endcase
				end
		default: dmem_read_w_local = 'b0;
		endcase
	end

	assign rd_o = rd_i;
	assign reg_we_o = reg_we_w & (~stall_i);
	assign reg_data_o = reg_data_r;
	assign dmem_out_o = dmem_read_w_local;
endmodule 