`timescale 1ns / 1ps
`include "define_alu_ctrl.vh"
`include "define_inst_dec.vh"
module maindec(
	input 	wire	[31:0] 	instr,
	output 	wire 			memtoreg,		// write back stage: source of data. 0: alu; 1: memory
	output 	wire 			memwrite,		// mem stage:		 control signal of write to data memory. 0: no; 1: yes
	output 	wire 			branch,			// decode stage:	 whether is a branch inst. 0: no; 1: yes
	output 	wire 			alusrc,			// execute stage:	 source of srcB. 0: regfile; 1: immediately
	output 	wire 			regdst,			// decode stage:	 final destination to regfile of data. 0: instrD[20:16]; 1: instrD[15:11] 
	output 	wire 			regwrite,		// decode stage:	 control signal of write to regfile. 0: no; 1: yes 
	output 	wire 			jump,			// decode stage:	 signal of jump instruction. 0: no; 1: yes
	output 	wire 			is_IMM			// decode stage:	 signal of immediately operator. 0: no; 1: yes
    );
	reg		[6:0] 	controls;
	wire 	[5:0] 	op;
	assign op = instr[31:26];
	assign {regwrite, regdst, alusrc, branch, memwrite, memtoreg, jump} = controls;
	always @(*) begin
		case (op)
			`OP_RTYPE	:	controls <= 7'b1100000;	//R-TYRE
			`OP_ANDI	:	controls <= 7'b1010000;
			`OP_XORI	:	controls <= 7'b1010000;
			`OP_LUI		:	controls <= 7'b1010000;
			`OP_ORI		:	controls <= 7'b1010000;
			6'b100011	:	controls <= 7'b1010010;	//LW
			6'b101011	:	controls <= 7'b0010100;	//SW
			6'b000100	:	controls <= 7'b0001000;	//BEQ
			6'b001000	:	controls <= 7'b1010000;	//ADDI
			6'b000010	:	controls <= 7'b0000001;	//J
			default		:  	controls <= 7'b0000000;	//illegal op
		endcase
	end
	assign is_IMM = (op[5:2] == 4'b0011) ? 1'b0 : 1'b1;		//andi, xori, lui, ori 无符号拓展
endmodule
