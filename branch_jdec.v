`timescale 1ns / 1ps
`include "define_inst_dec.vh"
`include "define_bj_control.vh"
module branch_jdec(
	input wire [31:0] a, b,
	input wire [31:0] instrD,
	output wire isBranchNeeded,		// whether to branch
	output wire isSaveReg31,		// 1 save to 31(jal, bltzal, bgezal) and 0 save to rd(jalr)
	output wire isSaveReg,			// PC+8 save to regfile, 1 is yes
	output wire isJumpToReg			// JR / JALR
);
	// 总结一下branch和j要做什么
	// AL: 保存PC+8到reg[31], 或者ALR保存到reg[rd]
	wire [5: 0]	op, funct;
	wire [4: 0] rt;
	assign op = instrD[31: 26];
	assign funct = instrD[5: 0];
	assign rt	 = instrD[20: 16];
	assign isBranchNeeded = (op == `OP_BEQ   ) ?	(a == b)
			 			  : (op == `OP_BNE   ) ?	(a != b)   
			 			  : (op == `OP_BGTZ  ) ?	($signed(a) >  0)  
			 			  : (op == `OP_BLEZ  ) ?	($signed(a) <= 0)  
			 			  : ((op == `OP_BLTZ  ) && (rt[0] == 1'b0)) ?	($signed(a) <  0)  // bltz, bltzal
			 			  : ((op == `OP_BGEZ  ) && (rt[0] == 1'b1)) ?	($signed(a) >= 0)  // bgez, bgezal	又是一个小细节，差点被坑
			 			  : 						1'b0;
	assign isSaveReg31 = (op == `OP_JAL) ? 1'b1 :
						 ((op == `OP_BLTZAL) &&	(rt[4] == 1'b1)) ? 1'b1 : 1'b0;	// 这一句实际包括bltzal和bgezal，小细节
	assign isSaveReg   = isSaveReg31 | ((funct == `FUNC_JALR) & (op == `OP_JALR));
	assign isJumpToReg = ((funct == `FUNC_JR) | (funct == `FUNC_JALR)) & (op == 6'b000000);
endmodule

