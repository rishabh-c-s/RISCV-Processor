`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:27:15 11/03/2019 
// Design Name: 
// Module Name:    pipeline_if 
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
module pipeline_if(
	input clk_i,
	input reset_i,
	
	// These two come from the EX stage
	input [31:0] pc_new_i,
   input if_branch_i, 
	
	// all the outputs go to ID stage after being registered
   output [31:0] instr_o,
	output [31:0] pc_o,
	
	output stall_load_o
   );
	 
// -------------------------
// Registers/wires
// -------------------------

reg [31:0] pc_r;

reg [31:0] m[0:31];

reg [4:0] rd_previous_r;
reg 		 rd_previous_activate_r;

reg [31:0] instr_o_r;
reg [31:0] pc_o_r;
reg stall_load_o_r;

wire [31:0] idata;

reg [31:0] pc_next_w;
reg stall_load_w;
	 
// -------------------------
// Reading from IMEM
// -------------------------

   initial begin $readmemh("imem3_ini.mem",m); end

   assign idata = m[pc_r[31:2]];
	
// -------------------------
// Setting rd_previous_r and rd_previous_activate_r
// -------------------------

always @(posedge clk_i)
begin
	if( reset_i )
	begin
		rd_previous_r <= 'b0;
		rd_previous_activate_r <= 'b0;
	end
	else
	begin
		rd_previous_r <= idata[11:7];	
		if( idata[6:2] == 5'b00000 )
		begin
			rd_previous_activate_r <= 1'b1;
		end
		else
		begin
			rd_previous_activate_r <= 1'b0;
		end
	end
end

// -------------------------
// Setting PC
// -------------------------

	always @(*)
	begin
		if(if_branch_i)
		begin
			pc_next_w = pc_new_i & 32'hfffffffc;
			stall_load_w = 'b0;
		end
		else
		begin
			if( (idata[6:2] == 5'b01101) && (idata[6:2] == 5'b00101) && (idata == 5'b11011) )
			begin
				pc_next_w = pc_r + 'd4;
				stall_load_w = 'b0;
			end
			else
			begin
				if( rd_previous_activate_r )
				begin
					if( ((idata[19:15] == rd_previous_r)) || (( (idata[6:2] == 5'b11000) || (idata[6:2] == 5'b01100) || (idata[6:2] == 5'b01000) ) && (idata[24:20] == rd_previous_r)) ) // whether rd = rs1
					begin
						pc_next_w = pc_r;
						stall_load_w = 'b1;
					end
					else
					begin
						pc_next_w = pc_r + 'd4;
						stall_load_w = 'b0;
					end
				end
				else
				begin
					pc_next_w = pc_r + 4'b0100;
					stall_load_w = 'b0;
				end
			end
		end
	end
	
	always @(posedge clk_i)
	begin
		if( reset_i )
		begin
			pc_r <= 'b0;
		end
		else
		begin
			pc_r <= pc_next_w;
		end
	end
	
// -----------------------
// Setting the Output registers
// -----------------------

// REG_IF
	always @( posedge clk_i )
	begin
		if(reset_i)
		begin
			instr_o_r      <= 'b0;
			pc_o_r         <= 'b0;
			stall_load_o_r <= 'b0;
		end
		else
		begin
			instr_o_r      <= idata;
			pc_o_r         <= pc_r;
			stall_load_o_r <= stall_load_w;
		end
	end
	assign instr_o      = instr_o_r;
	assign pc_o         = pc_o_r;
	assign stall_load_o = stall_load_o_r;

endmodule 