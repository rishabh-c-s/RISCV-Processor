`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    13:31:42 11/26/2019 
// Design Name: 
// Module Name:    top 
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
module top(
	input clk
);

	wire reset;
	
	// Outputs
	wire [31:0] pc;
	wire [31:0] x31;
	wire [31:0] x3;
	
	wire [35:0] vio_ctrl, ila_ctrl;
	
	// Instantiate the Unit Under Test (UUT)
	CPU CPU_main (
    .clk_i(clk), 
    .reset_i(reset), 
    .pc(pc),
	 .x31(x31),
	 .x3(x3)
   );
	
	icon icon_inst (
    .CONTROL0(vio_ctrl), // INOUT BUS [35:0]
    .CONTROL1(ila_ctrl) // INOUT BUS [35:0]
	);
	
	ila ila_inst (
    .CONTROL(ila_ctrl), // INOUT BUS [35:0]
    .CLK(clk), // IN
    .TRIG0(pc), // IN BUS [31:0]
    .TRIG1(x31), // IN BUS [31:0]
    .TRIG2(x3), // IN BUS [31:0]
    .TRIG3(reset) // IN BUS [0:0]
	);
	 
	vio vio_inst (
    .CONTROL(vio_ctrl), // INOUT BUS [35:0]
    .CLK(clk), // IN
    .ASYNC_OUT(reset), // OUT BUS [0:0]
    .SYNC_IN({x31,x3,pc}) // IN BUS [95:0]
	);
	
	 


endmodule
