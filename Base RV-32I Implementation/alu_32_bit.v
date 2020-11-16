`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    17:53:34 11/03/2019 
// Design Name: 
// Module Name:    alu_32_bit 
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
module alu_32_bit (
	input  wire [31:0]   in1,
	input  wire [31:0]   in2, 
	input  wire [3:0] op, 
	output wire [31:0]   out
);
	reg [31:0] out_w;
    	
	always @(*) 
	begin
     	case(op)
		4'b0000: out_w = in1 + in2;
		4'b0001: out_w = in1<<in2[3:0];
		4'b0010: out_w = $signed(in1) < $signed(in2);		
		4'b0011: out_w = in1 < in2;
		4'b0100: out_w = in1 ^ in2;
		4'b0101: out_w = in1 >> in2[3:0];
		4'b0110: out_w = in1 | in2;
		4'b0111: out_w = in1 & in2;
		4'b1000: out_w = in1 - in2;
		4'b1101: out_w = $signed(in1) >>> in2[3:0];
		// Branch instructions to follow, 'b1 means should branch, else shouldn't branch
		4'b1001: out_w = in1 == in2; // BEQ
		4'b1010: out_w = in1 != in2; // BNE
		4'b1011: out_w = $signed(in1) < $signed(in2); // BLT
		4'b1100: out_w = $signed(in1) >= $signed(in2); // BGE
		4'b1110: out_w = in1 < in2; // BLTU
		4'b1111: out_w = in1 >= in2; // BGEU
		default: out_w = 32'bx;
		endcase
	end
	
	assign out = out_w;

endmodule
