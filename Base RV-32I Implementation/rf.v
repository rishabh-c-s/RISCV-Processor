`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    17:58:23 11/03/2019 
// Design Name: 
// Module Name:    rf 
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
module rf(
    input clk,
    input [4:0] rs1,
    input [4:0] rs2,
    input [4:0] rd,
    input we,
    output [31:0] rv1,
    output [31:0] rv2,
    input [31:0] indata,
	 output [31:0] x31
    );
	 
	 reg [31:0] register_field[31:0];
	
integer i;	

initial
begin
	for(i=0; i<32; i=i+1)
	begin 
		register_field[i] <= 32'h00000000;
	end
end

// ------------------------------------
// Reading using Combinational Logic
// ------------------------------------

assign rv1 = register_field[rs1];
assign rv2 = register_field[rs2];
assign x31 = register_field['d31];

// ------------------------------------
// Writing using Sequential Logic
// ------------------------------------

always @(posedge clk)
begin
	if(we)
	begin
		if(rd == 5'b00000)
		begin
			register_field[rd] <= 'b0;
		end
		else
		begin
			register_field[rd] <= indata;
		end
	end
	else
	begin
		register_field[rd] <= register_field[rd];
	end
end

endmodule
