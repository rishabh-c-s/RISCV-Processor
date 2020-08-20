`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    01:13:01 11/24/2019 
// Design Name: 
// Module Name:    multiply 
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
module multiply #(
	parameter WIDTH = 32,
	parameter CTR_WIDTH = 7
) (
	input clk_i,
	input reset_i, // or start_i, in order to start the operation again
	input enable_i, // enable signal
	
	input [WIDTH-1:0] a_i,
	input [WIDTH-1:0] b_i,
	input [1:0]       mini_opcode_i,
	
	output [WIDTH-1:0] mul_out_o,
	output             valid_o
) ;
      
	// opcode
	// 00 : MUL 
	// 01 : MULH
	// 10 : MULHSU
	// 11 : MULHU
		
   reg [CTR_WIDTH-1:0] ctr_r;
	
	reg [(WIDTH*2)-1:0] multiplier;
	reg [(WIDTH*2)-1:0] multiplicand;
	
	reg [WIDTH:0] lower_product;
	reg [WIDTH-1:0] higher_product;
	
	reg [(WIDTH*2)-1:0] shifted_multiplier;
	
	reg valid_1, valid_2, valid_3;
	
	
	
	always @(*)
	begin
		case(mini_opcode_i)
		2'b00,
		2'b01: 
				begin
					multiplier   = {(1<<WIDTH)-a_i[WIDTH-1],a_i};
					multiplicand = {(1<<WIDTH)-b_i[WIDTH-1],b_i};
				end
		2'b10: 
				begin
					multiplier   = {(1<<WIDTH)-a_i[WIDTH-1],a_i};
					multiplicand = {32'h00000000,b_i};
				end
		2'b11: 
				begin
					multiplier   = {32'h00000000,a_i};
					multiplicand = {32'h00000000,b_i};
				end
		default:
				begin
					multiplier   = 'b0;
					multiplicand = 'b0;
				end
		endcase
	end
		
   always @(posedge clk_i)
	begin
		if (reset_i) 
		begin
			valid_1            <= 'b0;
			shifted_multiplier <= 'b0;
			ctr_r              <= 'b0;
		end
      else 
		begin 
			if(ctr_r[CTR_WIDTH-1] == 'b0) 
			begin
				ctr_r <= ctr_r + 'b1;
				valid_1 <= 1'b0;
				if(multiplicand[ctr_r])
				begin
					shifted_multiplier <= (multiplier<<ctr_r);
				end
				else
				begin
					shifted_multiplier <= 'b0;
				end
			end
			else
			begin
				if(valid_1)
				begin
					shifted_multiplier <= 'b0;
					ctr_r   				 <= 'b0;
					valid_1				 <= 'b0;
				end
				else
				begin
					shifted_multiplier <= shifted_multiplier;
					ctr_r   				 <= ctr_r;
					valid_1				 <= 'b1;
				end
			end
		end
	end
	
	always @(posedge clk_i)
	begin
		if(reset_i)
		begin
			valid_2       <= 'b0;
			lower_product <= 'b0;
		end
		else
		begin
			valid_2 <= valid_1;
			if(valid_1)
			begin
				lower_product <= lower_product;
			end
			else
			begin
				lower_product <= lower_product + shifted_multiplier[31:0];
			end
		end
	end
	
	always @(posedge clk_i)
	begin
		if(reset_i)
		begin
			valid_3        <= 'b0;
			higher_product <= 'b0;
		end
		else
		begin
			valid_3 <= valid_2;
			if(valid_2)
			begin
				higher_product <= higher_product;
			end
			else
			begin
				higher_product <= higher_product + lower_product[32] + shifted_multiplier[63:32];
			end
		end
	end
	
	assign mul_out_o = (mini_opcode_i == 2'b00) ? lower_product : higher_product;
	assign valid_o   = valid_3 && enable_i;
	
endmodule // seqmult
