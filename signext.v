`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/11/02 14:29:33
// Design Name: 
// Module Name: signext
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module signext(
	input 	wire	[15:0] 	a,
	input 	wire	 		is_IMM,
	output 	wire	[31:0] 	y
    );

	assign y = is_IMM 	?	{ 16'b0, a }
						:	{ { 16 { a[15] } }, a };
endmodule
