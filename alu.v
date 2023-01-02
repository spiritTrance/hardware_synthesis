`timescale 1ns / 1ps
`include "define_alu_ctrl.vh"

/*	port statement
 *	a, b: operator source, a is rs and b is rt in MIPS
 *	op: alu arithmetic signal
 *	y: arithmetic result
 */
module alu(
	input 	wire	[31:0] 	a, b,
	input 	wire	[4:0] 	op,
	output 	reg		[31:0] 	y,
	input 	wire	[4:0]	sa,
	input 	wire 	[63:0]	HILO,
	output 	reg 			overflow,
	output 	wire 			zero
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
			// shift arithmetic
				// logic shift: <</>>; arithmetic shift: <<</>>>
				// NOTE THAT sys function $signed() can make it considered to be a signed number
			`SIG_ALU_SLL :	y = b << sa;
			`SIG_ALU_SRL :	y = b >> sa;
			`SIG_ALU_SRA :	y = $signed(b) >>> sa;
			`SIG_ALU_SLLV:	y = b << a;
			`SIG_ALU_SRLV:	y = b >> a;
			`SIG_ALU_SRAV:	y = $signed(b) >>> a;
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
