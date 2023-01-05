`timescale 1ns / 1ps
`include "define_alu_ctrl.vh"

/*	port statement
 *	a, b: operator source, a is rs and b is rt in MIPS
 *	op: alu arithmetic signal
 *	y: arithmetic result
 */
module alu(
	input 	wire 			clk, rst,
	input 	wire	[31:0] 	a, b,
	input 	wire	[4:0] 	op,
	output 	reg		[31:0] 	y,
	input 	wire	[4:0]	sa,
	input 	wire 	[63:0]	HILO_i,
	output 	wire 	[63:0]	HILO_o,
	output  wire			isMulOrDivComputing,	
	output 	wire 			isMulOrDivResultOk,
	output 	reg 			overflow,
	output 	wire 			zero
	// output	wire			divByZero			// TODO: 除零例外
    );
	// arithmetic result driver
	// 计算结果y的驱动
	always @(*) begin
		case (op[4:0])
			// logic
			`SIG_ALU_AND:	y = a & b;
			`SIG_ALU_OR :	y = a | b;
			`SIG_ALU_XOR:	y = a ^ b;
			`SIG_ALU_NOR:	y = ~(a | b);
			`SIG_ALU_LUI:	y = {b[15:0], 16'b0};
			// shift
				// logic shift: <</>>; arithmetic shift: <<</>>>
				// NOTE THAT sys function $signed() can make it considered to be a signed number
			`SIG_ALU_SLL :	y = b << sa;
			`SIG_ALU_SRL :	y = b >> sa;
			`SIG_ALU_SRA :	y = $signed(b) >>> sa;
			`SIG_ALU_SLLV:	y = b << a;
			`SIG_ALU_SRLV:	y = b >> a;
			`SIG_ALU_SRAV:	y = $signed(b) >>> a;
			// data move	冒险解决的需要
			`SIG_ALU_MFHI:	y = HILO_i[63: 32];
			`SIG_ALU_MFLO:	y = HILO_i[31: 0 ];
			// arithmetic
			`SIG_ALU_ADD  : y = $signed(a) + $signed(b);
			`SIG_ALU_ADDU : y = a + b;
			`SIG_ALU_SUB  : y = $signed(a) - $signed(b);
			`SIG_ALU_SUBU : y = a - b;
			`SIG_ALU_SLT  : y = $signed(a) < $signed(b) ? 1'b1 : 1'b0; 
			`SIG_ALU_SLTU : y = a < b ? 1'b1 : 1'b0;
			// branch and jump - al/alr
			`SIG_ALU_PC8  : y = a + 32'b1000;
			// fail
			`SIG_ALU_FAIL:	y <= 32'b0;
			default : 		y <= 32'b0;
		endcase	
	end

	// 乘除法处理
	wire [63: 0] result_mul, result_div;
	wire isMul, isDiv, sign;
	wire isMulResultOk, isDivResultOk;
	assign isMul = (op == `SIG_ALU_MULT) | (op == `SIG_ALU_MULTU);
	assign isDiv = (op == `SIG_ALU_DIV) | (op == `SIG_ALU_DIVU);
	assign sign = (op == `SIG_ALU_DIV) | (op == `SIG_ALU_MULT);
	assign isMulOrDivResultOk = isMulResultOk | isDivResultOk;
	assign isMulOrDivComputing = (isMul | isDiv) & (~isMulOrDivResultOk); 
	mul mul_example(clk, rst, isMul, a, b, sign, isMulResultOk, result_mul);		// 乘法器件
	div div_example(clk, rst, sign, a, b, isDiv & ~isDivResultOk, 1'b0, result_div, isDivResultOk);	// 除法器件

	// overflow driver
	// 溢出信号驱动
	always @(*) begin
		case (op[4:0])
			default : overflow <= 1'b0;
		endcase	
	end
	assign zero = (y == 32'b0);


	// HILO
	assign HILO_o = isMul & isMulResultOk ? result_mul:
				  	isDiv & isDivResultOk ? result_div:
				  	64'b0;
endmodule
