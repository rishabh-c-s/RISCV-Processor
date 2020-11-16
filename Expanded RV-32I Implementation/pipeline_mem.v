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
	input [31:0] dmem_data_i,	//DMEM Write Data or multiply input 2
	input [5:0] opcode_i,	 	//6-Bit Instruction Opcode
	input [4:0] rd_i,		 		//Register Write Address
	input stall_i,					//Stall
	input [31:0] mul_in1_i,  // multiply input 1
	
	input valid_stall_i,
		
	//Output			
	output [5:0] opcode_o,	 	//6-Bit Opcode
	output [31:0] alu_out_o, 	//ALU Out
	output [4:0] rd_o,		 	//Register Write Address
	
	output [31:0] peripheral_read_o,
	output [31:0] dmem_read_o,
	output [31:0] mul_read_o,
	
	output valid_stall_o,

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
	
	reg [31:0] peripheral_read_o_r;
	reg [31:0] dmem_read_o_r;
	reg [31:0] mul_read_o_r;
	
	reg multiply_pulse;

	//-------------------------------//
	//			Wire Definition			//
	//-------------------------------//
	
	wire [3:0] dmem_we_w;					//Write Enable Wire
	
	wire [31:0] dmem_corr_write_data_w;	//DMEM Write Modified Wire
	
	wire [31:0] peripheral_read_w;
	wire [31:0] dmem_read_w;
	wire [31:0] mul_read_w;

	wire peripheral_ce_w;
	wire peripheral_we_w;					//Peripheral Write Enable 
	
	wire main_ce_w;
	wire dmem_ce_w;
	wire valid_main_w;
	wire multiply_ce_w;
	
	wire valid_dmem_w;
	wire valid_peripheral_w;
	wire valid_mul_w;
	
	wire multiply_pulse_main;
	
	
	
	// -----------------
	// -----------------
	
	assign main_ce_w = (opcode_i[5:3] == 3'b100 || opcode_i[5:3] == 3'b101 ) ? 1'b1 : 1'b0;
	assign peripheral_ce_w = (alu_out_i >= 'd512) && (main_ce_w) ? 1'b1 : 1'b0;
	assign dmem_ce_w = (alu_out_i <= 'd512) && (main_ce_w) ? 1'b1: 1'b0;

	assign multiply_ce_w = (opcode_i[5:2] == 4'b1111) ? 1'b1 : 1'b0;
	
	always @(posedge clk)
	begin
		if(reset)
		begin
			multiply_pulse <= 1'b1;
		end
		else
		begin
			if(multiply_ce_w)
			begin
				multiply_pulse <= 1'b0;
			end
			else
			begin
				multiply_pulse <= 1'b1;
			end
		end
	end
	assign multiply_pulse_main = multiply_ce_w && multiply_pulse;
	
	//-------------------------------//
	//			DMEM Instance				//
	//-------------------------------//
	
	dmem dmem_instance(
		.clk(clk),																//Clock
		.reset(reset),
		.daddr_i(alu_out_i),													//Address
		.dwdata_i(dmem_corr_write_data_w),								//Write Data
		.we_i(dmem_we_w&{4{~stall_i}}),		//Write Enable
		.ce_i(dmem_ce_w),
		.drdata_o(dmem_read_w),	// output is here
		.valid_o(valid_dmem_w)
	);
	
	//--------------------------//
	//    Peripheral Instance   //
	//--------------------------//
	
	peripheral accumulator(
		.clk(clk),						// Clock	 
		.reset(reset),					// Reset
		.ce(peripheral_ce_w),						// Chip Enable
		.we(peripheral_we_w&(~stall_i)),						// Write Enable
		.addr(alu_out_i[3:2]),  					// Address Reference (For selecting Operation)
		.valid_stall_i(valid_stall_i),
		.wdata(dmem_corr_write_data_w),					// Write Data (to be accumulated)
		.rdata(peripheral_read_w),	// output is here
		.valid_o(valid_peripheral_w)
		);
	//--------------------------//
	//    Multiply  Instance    //
	//--------------------------//
	
	multiply multiplier (
    .clk_i(clk), 
    .reset_i(reset | multiply_pulse_main), 
	 .enable_i(multiply_ce_w),
    .a_i(mul_in1_i), 
    .b_i(dmem_data_i), 
    .mini_opcode_i(opcode_i[1:0]), 
    .mul_out_o(mul_read_w), 
    .valid_o(valid_mul_w)
    );
	
		
	//-------------------------------//
	//			DMEM Input Decoder		//
	//-------------------------------//
	
	dmem_decoder dmem_decoder_instance(
			.alu_out_i(alu_out_i),					//ALU Output
			.instr_opcode_i(opcode_i),				//6 Bit Instruction Opcode
			.indata_i(dmem_data_i),					//Raw Write Data
			.w_data_o(dmem_corr_write_data_w),	//Output Write Data for DMEM
			.peripheral_ce(peripheral_ce_w),		//Peripheral Chip Enable
			.we_o(dmem_we_w),							//Write Enable system for DMEM Write Enable
			.per_we_o(peripheral_we_w)	//Write Enable system for Peripheral Write Enable
	);
	
	//-------------------------------//
	//			Pipelining Action			//
	//-------------------------------//
	
	always @(posedge(clk))
		begin
			//Reset all registers
			if(reset) begin
				opcode_r				  <= 'b0;
				alu_out_r 			  <= 'b0;
				rd_r    				  <= 'b0;
				stall_r   			  <= 'b0;
				peripheral_read_o_r <= 'b0;
				dmem_read_o_r 		  <= 'b0;
				mul_read_o_r		  <= 'b0;
			end
			//Set input values into corresponding registers
			else 
			begin
				if(valid_stall_i)
				begin
					opcode_r  			  <= opcode_r;
					alu_out_r 			  <= alu_out_r;
					rd_r  			     <= rd_r;
					stall_r   			  <= stall_r;
					peripheral_read_o_r <= peripheral_read_o_r;
					dmem_read_o_r 		  <= dmem_read_o_r;
					mul_read_o_r 		  <= mul_read_o_r;
				end
				else
				begin
					opcode_r				  <= opcode_i;
					alu_out_r 			  <= alu_out_i;
					rd_r      			  <= rd_i;
					stall_r			     <= stall_i;
					peripheral_read_o_r <= peripheral_read_w;
					dmem_read_o_r 		  <= dmem_read_w;
					mul_read_o_r		  <= mul_read_w;
				end
			end
		end
		
	//Set output from pipeline registers
	
	assign opcode_o =	 opcode_r;		//6-Bit Opcode
	assign alu_out_o = alu_out_r;		//ALU Output
	assign rd_o = rd_r;					//Register Write Address
	assign stall_o = stall_r;			//Stall
	assign peripheral_read_o = peripheral_read_o_r;
	assign dmem_read_o = dmem_read_o_r;
	assign mul_read_o = mul_read_o_r;

	assign valid_main_w = (valid_peripheral_w && peripheral_ce_w) ||  (dmem_ce_w && valid_dmem_w) || (multiply_ce_w && valid_mul_w);
	assign valid_stall_o = ((main_ce_w == 1'b1 || multiply_ce_w) && (valid_main_w == 1'b0) ) ? 1'b1 : 1'b0;

endmodule 
