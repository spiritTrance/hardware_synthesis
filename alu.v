`timescale 1ns / 1ps
`include "define_alu_ctrl.vh"

/*	port statement
 *	a, b: operator source
 *	op: alu arithmetic signal
 *	y: arithmetic result
 */
module alu(
	input 	wire	[31:0] a,b,
	input 	wire	[4:0] op,
	output 	reg		[31:0] y,
	output 	reg 	overflow,
	output 	wire 	zero
    );
	// arithmetic result driver
	// 计算结果驱动
	always @(*) begin
		case (op[4:0])
			// logic arithmetic
			`SIG_ALU_AND:	y = a & b;
			`SIG_ALU_OR :	y = a | b;
			`SIG_ALU_XOR:	y = a ^ b;
			`SIG_ALU_NOR:	y = ~(a | b);
			`SIG_ALU_LUI:	y = {b[15:0], 16'b0};
			// fail
			`SIG_ALU_FAIL:	y <= 32'b0;
			default : 		y <= 32'b0;
		endcase	
	end
	assign zero = (y == 32'b0);

	// overflow driver
	// 溢出信号驱动
	always @(*) begin
		case (op[4:0])
			default : overflow <= 1'b0;
		endcase	
	end
endmodule
