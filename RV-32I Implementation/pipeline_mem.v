`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:32:45 11/09/2019 
// Design Name: 
// Module Name:    pipeline_mem 
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
module pipeline_mem(
	//Input
	input clk,					 	//Clock
	input reset,				 	//Reset
	input [31:0] alu_out_i,  	//ALU Output
	input [31:0] dmem_data_i,	//DMEM Write Data
	input [5:0] opcode_i,	 	//6-Bit Instruction Opcode
	input [4:0] rd_i,		 		//Register Write Address
	input stall_i,					//Stall
		
	//Output			
	output [31:0] dmem_out_o,	//DMEM Out Value
	output [5:0] opcode_o,	 	//6-Bit Opcode
	output [31:0] alu_out_o, 	//ALU Out
	output [4:0] rd_o,		 	//Register Write Address
	output stall_o					//Stall
);

	//-------------------------------//
	//			Register Definition		//
	//-------------------------------//
	
	reg [31:0] dmem_out_r;	//DMEM Out Value
	reg [5:0] opcode_r;	 	//6-Bit Opcode
	reg [31:0] alu_out_r; 	//ALU Out
	reg [4:0] rd_r;		 	//Register Write Address
	reg stall_r;				//Stall	

	//-------------------------------//
	//			Wire Definition			//
	//-------------------------------//
	
	wire [3:0] dmem_we_w;					//Write Enable Wire
	wire [31:0] dmem_corr_write_data_w;	//DMEM Write Modified Wire
	wire [31:0] dmem_read_w;				//DMEM Read Wire
	reg [31:0] dmem_outdata;
	
	//-------------------------------//
	//			DMEM Instance				//
	//-------------------------------//
	
	dmem dmem_instance(
		.clk(clk),										//Clock
		.reset(reset),
		.daddr_i(alu_out_i),							//Address
		.dwdata_i(dmem_corr_write_data_w),		//Write Data
		.we_i(dmem_we_w&{4{~stall_i}}),								//Write Enable
		.drdata_o(dmem_read_w)						//Read Data
	);
	
	
	//-------------------------------//
	//			DMEM Input Decoder		//
	//-------------------------------//
	
	dmem_decoder dmem_decoder_instance(
			.alu_out_i(alu_out_i),					//ALU Output
			.instr_opcode_i(opcode_i),				//6 Bit Instruction Opcode
			.indata_i(dmem_data_i),					//Raw Write Data
			.w_data_o(dmem_corr_write_data_w),	//Output Write Data for DMEM
			.we_o(dmem_we_w)							//Write Enable system for Write Enable
	);
	
	
	
	//-------------------------------//
	//			Pipelining Action			//
	//-------------------------------//
	
	always@(posedge(clk))
		begin
			//Reset all registers
			if(reset) begin
				dmem_out_r <= 'b0;
				opcode_r <= 'b0;
				alu_out_r <= 'b0;
				rd_r <= 'b0;
				stall_r <= 'b0;
			end
			//Set input values into corresponding registers
			else begin
				dmem_out_r <= dmem_outdata;
				opcode_r <= opcode_i;
				alu_out_r <= alu_out_i;
				rd_r <= rd_i;
				stall_r <= stall_i;
			end
		end
	
	// Setting correct data read from DMEM
	always @(*)
	begin
		case(opcode_i[2:0])
		3'b000:
				begin
					case(alu_out_i[1:0])
					2'b00: dmem_outdata = {(1<<24)-dmem_read_w[7],dmem_read_w[7:0]};
					2'b01: dmem_outdata = {(1<<24)-dmem_read_w[15],dmem_read_w[15:8]};
					2'b10: dmem_outdata = {(1<<24)-dmem_read_w[23],dmem_read_w[23:16]};
					2'b11: dmem_outdata = {(1<<24)-dmem_read_w[31],dmem_read_w[31:24]};
					default: dmem_outdata = 'b0;
					endcase
				end
		3'b001:
				begin
					case(alu_out_i[1:0])
					2'b00: dmem_outdata = {(1<<16)-dmem_read_w[15],dmem_read_w[15:0]};
					2'b10: dmem_outdata = {(1<<16)-dmem_read_w[31],dmem_read_w[31:16]};
					default: dmem_outdata = 'b0;
					endcase
				end
		3'b010: dmem_outdata = dmem_read_w;
		3'b100:
				begin
					case(alu_out_i[1:0])
					2'b00: dmem_outdata = {24'b0,dmem_read_w[7:0]};
					2'b01: dmem_outdata = {24'b0,dmem_read_w[15:8]};
					2'b10: dmem_outdata = {24'b0,dmem_read_w[23:16]};
					2'b11: dmem_outdata = {24'b0,dmem_read_w[31:24]};
					default: dmem_outdata = 'b0;
					endcase
				end
		3'b101:
				begin
					case(alu_out_i[1:0])
					2'b00: dmem_outdata = {16'b0,dmem_read_w[15:0]};
					2'b10: dmem_outdata = {16'b0,dmem_read_w[31:16]};
					default: dmem_outdata = 'b0;
					endcase
				end
		default: dmem_outdata = 'b0;
		endcase
	end
	
	
	
	//Set output from pipeline registers
	
	assign dmem_out_o = dmem_out_r;	//DMEM Out Value
	assign opcode_o =	 opcode_r;		//6-Bit Opcode
	assign alu_out_o = alu_out_r;		//ALU Output
	assign rd_o = rd_r;					//Register Write Address
	assign stall_o = stall_r;			//Stall
	
endmodule 
