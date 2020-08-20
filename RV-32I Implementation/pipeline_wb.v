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
	
	input [31:0] dmem_in_i,
	input [5:0] opcode_i,
	input [4:0] rd_i,
	input [31:0] alu_out_i,
	input stall_i,
	
	//Output
	
	output [31:0] reg_data_o,
	output reg_we_o,
	output [4:0] rd_o
);


	reg reg_we_w;
	reg [31:0] reg_data_r;
	//----------------------------------//
	//			Register Input Decoder		//
	//----------------------------------//
	
	always@(*) begin
		case(opcode_i[5])
			//ALU Operations
			1'b0:
				begin
					reg_data_r<=alu_out_i;
					reg_we_w <= 1;
				end
			//Other Operations
			1'b1:
				begin
					case(opcode_i[4:3])
						//Branch and Store
						2'b10,2'b01:
							begin
								reg_data_r<=32'b0;
								reg_we_w <= 0;
							end
						//Jump, AUPIC, LUI
						2'b11:
							begin
								reg_data_r<=alu_out_i;
								reg_we_w <= 1;	
							end
						//Load
						2'b00:
							begin
								reg_data_r<=dmem_in_i;
								reg_we_w <= 1;	
							end
					endcase
				end
		endcase
	end

	assign rd_o = rd_i;
	assign reg_we_o = reg_we_w & (~stall_i);
	assign reg_data_o = reg_data_r;
endmodule 