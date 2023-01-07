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
	input 	wire	[31:0]	cp0_i,
	input  	wire			flushE,
	output 	wire 	[63:0]	HILO_o,
	output  wire			isMulOrDivComputing,	
	output 	wire 			isMulOrDivResultOk,
	output 	wire 			overflow,
	output 	wire 			zero
	// output	wire			divByZero			// TODO: 除零例外
    );
	// arithmetic result driver
	// 计算结果y的驱动
	wire addOverflow, subOverflow;
	always @(*) begin
		case (op)
			// logic
			`SIG_ALU_AND:	y = a & b;
			`SIG_ALU_OR :	y = a | b;
			`SIG_ALU_XOR:	y = a ^ b;
			`SIG_ALU_NOR:	y = ~(a | b);
			`SIG_ALU_LUI:	y = {b[15:0], 16'b0};
			// shift
				// logic shift: <</>>; arithmetic shift: <<</>>>
				// NOTE THAT sys function $signed() can make it considered to be a signed number
			`SIG_ALU_SLL :	y = b << sa[4:0];
			`SIG_ALU_SRL :	y = b >> sa[4:0];
			`SIG_ALU_SRA :	y = $signed(b) >>> sa[4:0];
			`SIG_ALU_SLLV:	y = b << a[4:0];
			`SIG_ALU_SRLV:	y = b >> a[4:0];
			`SIG_ALU_SRAV:	y = $signed(b) >>> a[4:0];
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
			// load and store:
			`SIG_ALU_MEM  :	y = $signed(a) + $signed(b);
			// mfc0:	针对通用寄存器冒险解决的需要
			`SIG_ALU_MFC0 : y = cp0_i;
			// fail
			`SIG_ALU_FAIL:	y = 32'b0;
			default : 		y = 32'b0;
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
	mul mul_example(clk, rst, isMul, a, b, sign, 1'b0, isMulResultOk, result_mul);		// 乘法器件
	div div_example(clk, rst, sign, a, b, isDiv & ~isDivResultOk, 1'b0, result_div, isDivResultOk);	// 除法器件

	// overflow case；
	// a[31] b[31] 1'b1, y[31] 1'b0
	// a[31] b[31] 1'b0, y[31] 1'b1
	assign addOverflow = (op == `SIG_ALU_ADD) ? // 是否为add和sub指令
							(a[31] ^ b[31]) ? 1'b0 :	//两个操作数是否异号，异号则一定不会溢出
								 (a[31] ^ y[31]) ? 1'b1 : 1'b0 : 1'b0;	// 输入和输出的符号位，如果异号则发生溢出，否则没有；最后一个标识不为add和sub
	assign subOverflow = (op == `SIG_ALU_SUB) ? 
							~(a[31] ^ b[31]) ? 1'b0 :	// 两个操作数是否同号，同号则一定不溢出
							 (a[31] ^ y[31]) ? 1'b1 : 1'b0 : 1'b0;							// 两种情况：正数减负数，负数减正数，正确结果是正数和负数，即结果与被减数同号，如果相异，异或符号位必然为1
	assign overflow = addOverflow | subOverflow;
	assign zero = (y == 32'b0);

	// HILO
	assign HILO_o = isMul & isMulResultOk ? result_mul:
				  	isDiv & isDivResultOk ? result_div:
				  	64'b0;
endmodule
