`timescale 1ns / 1ps

module signext(
	input 	wire	[15:0] 	a,
	input 	wire	 		is_UIMM,
	output 	wire	[31:0] 	y
    );

	assign y = is_UIMM 	?	{ 16'b0, a }
						:	{ { 16 { a[15] } }, a };
endmodule
