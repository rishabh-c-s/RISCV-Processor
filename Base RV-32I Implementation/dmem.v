`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:39:19 11/09/2019 
// Design Name: 
// Module Name:    dmem 
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
module dmem(
	//Input
	input clk,					//Clock
	input reset,
	input [31:0] daddr_i,	//Address
	input [31:0] dwdata_i,	//Write Data
	input [3:0] we_i,		//Write Enable
	//Output
	output [31:0] drdata_o	//Read Data
);

		reg [7:0] m_r[0:127];
		initial $readmemh("dmem_ini.mem",m_r);

		wire [31:0] add0_w,add1_w,add2_w,add3_w;

		//-------------------------------------------//
		// 				Address Decoding  				//
		//-------------------------------------------//
		assign add0_w = (daddr_i & 32'hfffffffc) + 32'h00000000;
		assign add1_w = (daddr_i & 32'hfffffffc) + 32'h00000001;
		assign add2_w = (daddr_i & 32'hfffffffc) + 32'h00000002;
		assign add3_w = (daddr_i & 32'hfffffffc) + 32'h00000003;


		//-------------------------------------------//
		// 					Set Read Data		  			//
		//-------------------------------------------//
		assign drdata_o = {m_r[add3_w],m_r[add2_w],m_r[add1_w],m_r[add0_w]};


		//-------------------------------------------//
		// 					Set Write Data		  			//
		//-------------------------------------------//

		always @(posedge clk) begin
		  
			if(reset) begin
				$readmemh("dmem_ini.mem",m_r);
			end
			else begin  
				if (we_i[0]==1)
					m_r[add0_w]= dwdata_i[7:0];
				if (we_i[1]==1)
					m_r[add1_w]= dwdata_i[15:8];
				if (we_i[2]==1)
					m_r[add2_w]= dwdata_i[23:16];
				if (we_i[3]==1)
					m_r[add3_w]= dwdata_i[31:24];
			end
		end

endmodule 
