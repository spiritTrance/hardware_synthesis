`timescale 1ns / 1ps
`include "define_alu_ctrl.vh"
`include "define_inst_dec.vh"
module maindec(
	input 	wire	[31:0] 	instr,
	output 	wire 			memtoreg,		// write back stage: source of data. 0: alu; 1: memory
	output 	wire 			branch,			// decode stage:	 whether is a branch inst. 0: no; 1: yes
	output 	wire 			alusrc,			// execute stage:	 source of srcB. 0: regfile; 1: immediately
	output 	wire 			regdst,			// decode stage:	 final destination to regfile of data. 0: instrD[20:16]; 1: instrD[15:11] 
	output 	wire 			regwrite,		// decode stage:	 control signal of write to regfile. 0: no; 1: yes 
	output 	wire 			jump,			// decode stage:	 signal of jump instruction. 0: no; 1: yes
	output 	wire 			is_IMM,			// decode stage:	 signal of immediately operator. 0: no; 1: yes
	output  wire	[1: 0]	HILO_en,		// decode stage:	 hilo enable signal. HILO_we[1] for hi and [0] for lo
	output  wire			is_dataMovWrite,		// decode stage:	 whether is data move inst. 1: yes; 0: no
	output  wire			is_dataMovRead,		// decode stage:	 whether is data move inst. 1: yes; 0: no
	output  wire			isMulOrDiv,		//decode stage:	whether is mul or div inst.
	output 	wire			isMemDataReadSigned,	// write back stage: whether lb, lh, lbu, lhu
	output	wire 	[3: 0]	memInfo_we_bhw  // decode stage: for mem inst, include 4 signals: memwrite, byte, half, word operation
);
	reg		[5:0] 	controls;
	reg 	[3:0]	mem_ctrlsigs;
	wire 	[5:0] 	op, funct;
	wire 	[4:0]	rt;
	wire			is_dataMov;
	wire			operateHI, operateLO, readHILO, writeHILO;
	assign op = instr[31:26];
	assign funct = instr[5:0];
	assign rt = instr[20:16];

	// regwrite, regdst, alusrc, branch, memtoreg, jump
	assign {regwrite, regdst, alusrc, branch, memtoreg, jump} = controls;
	always @(*) begin
		case (op)
			// logic arithmetic instruction
			`OP_RTYPE	:		//R-TYRE
				case (funct)
					// logic
					`FUNC_AND	:	controls = 6'b110000;
					`FUNC_OR	:	controls = 6'b110000;
					`FUNC_XOR	:	controls = 6'b110000;
					`FUNC_NOR	:	controls = 6'b110000;
					// shift
					`FUNC_SLL 	:	controls = 6'b110000;
					`FUNC_SRL 	:	controls = 6'b110000;
					`FUNC_SRA 	:	controls = 6'b110000;
					`FUNC_SLLV	:	controls = 6'b110000;
					`FUNC_SRLV	:	controls = 6'b110000;
					`FUNC_SRAV	:	controls = 6'b110000;
					// data move
					`FUNC_MFHI	:	controls = 6'b110000;
					`FUNC_MFLO	:	controls = 6'b110000;
					`FUNC_MTHI	:	controls = 6'b000000;
					`FUNC_MTLO	:	controls = 6'b000000;
					// arithmetic
					`FUNC_ADD  	:	controls = 6'b110000;
					`FUNC_ADDU 	:	controls = 6'b110000;
					`FUNC_SUB  	:	controls = 6'b110000;
					`FUNC_SUBU 	:	controls = 6'b110000;
					`FUNC_SLT  	:	controls = 6'b110000;
					`FUNC_SLTU 	:	controls = 6'b110000;
					// 存疑，等会看看
					`FUNC_MULT 	:	controls = 6'b000000;
					`FUNC_MULTU	:	controls = 6'b000000;
					`FUNC_DIV  	:	controls = 6'b000000;
					`FUNC_DIVU 	:	controls = 6'b000000;
					// jump
					`FUNC_JR  	:	controls = 6'b000001;
					`FUNC_JALR	:	controls = 6'b110001;
					default:		controls = 6'b000000;
				endcase
			// I-type 
			// {regwrite, regdst, alusrc, branch, memwrite, memtoreg, jump}
			// --- logic
			`OP_ANDI	:	controls = 6'b101000;
			`OP_XORI	:	controls = 6'b101000;
			`OP_LUI		:	controls = 6'b101000;
			`OP_ORI		:	controls = 6'b101000;
			// shift arithmetic instruction
				// For all shift instruction are R-type, so the control signal is omitted as OP_RTYPE
			// data move instruction
				// For all shift instruction are R-type, so the control signal is omitted as OP_RTYPE
			// --- arithmetic
    		`OP_ADDI    : 	controls = 6'b101000;
    		`OP_ADDIU   : 	controls = 6'b101000;
    		`OP_SLTI    : 	controls = 6'b101000;
    		`OP_SLTIU   : 	controls = 6'b101000;
			// branch and jump	注意是自己写的，没检查，注意是否有bug
			// 对于AL来说，不是ALR，均保存在31号，只有JALR保存在rd，因此其为regdst为1
			`OP_J     	:	controls = 6'b000001;
			`OP_JAL   	:	controls = 6'b100001;
			`OP_BEQ   	:	controls = 6'b000100;
			`OP_BNE   	:	controls = 6'b000100;
			`OP_BGTZ  	:	controls = 6'b000100;
			`OP_BLEZ  	:	controls = 6'b000100;
			6'b000001:		controls = {rt[4], 5'b00100};	// bltz, bgez, bltzal, bgetal特判，为al则rt最高位为1，根据规范
			// memory
			`OP_LB 		:	controls = 6'b101010;
			`OP_LBU		:	controls = 6'b101010;
			`OP_LH 		:	controls = 6'b101010;
			`OP_LHU		:	controls = 6'b101010;
			`OP_LW 		:	controls = 6'b101010;
			`OP_SB 		:	controls = 6'b001000;
			`OP_SH 		:	controls = 6'b001000;
			`OP_SW 		:	controls = 6'b001000;
			// default
			default		:  	controls = 6'b000000;	//illegal op
		endcase
	end
	// immediately number
	assign is_IMM = (op[5:2] == 4'b0011) ? 1'b1 : 1'b0;		//andi, xori, lui, ori 无符号拓展
	// HILO signal
	assign is_dataMov = ( op != `OP_RTYPE ) ? 1'b0 :
						( funct[5:2] == 4'b0100 ) ? 1'b1: 1'b0;		// 是否为数据移动指令，但注意传到数据通路的时候，由于是用来做多路选择的，取值为0则为乘除法
	assign isMulOrDiv = ( op != `OP_RTYPE ) ? 1'b0 :
						( funct[5:2] == 4'b0110 ) ? 1'b1: 1'b0;		// 是否为乘除法
	assign writeHILO = ( isMulOrDiv | ( is_dataMov & funct[0] ) ) == 1'b1 ? 1'b1: 1'b0;		// 是否写HILO
	assign readHILO = ( is_dataMov & (~funct[0]) ) == 1'b1 ? 1'b1: 1'b0;				// 是否读HILO
	assign operateHI = ( isMulOrDiv | ( is_dataMov & (~funct[1]) ) ) == 1'b1 ? 1'b1: 1'b0;	// 是否对HI操作
	assign operateLO = ( isMulOrDiv | ( is_dataMov & funct[1] ) ) == 1'b1 ? 1'b1: 1'b0;		// 是否对LO操作
	// --- HILO output signal
	assign is_dataMovWrite = is_dataMov & writeHILO;
	assign is_dataMovRead = is_dataMov & readHILO;
	assign HILO_en = {operateHI, operateLO};

	// memread_en and memwrite enable

	assign isMemDataReadSigned = ~((op == `OP_LBU) | (op == `OP_LHU));
	assign memInfo_we_bhw = mem_ctrlsigs;	// write, byte, half, word
	always @(*) begin
		case(op)
			`OP_LB :	mem_ctrlsigs = 4'b0_100;
			`OP_LBU:	mem_ctrlsigs = 4'b0_100;
			`OP_LH :	mem_ctrlsigs = 4'b0_010;
			`OP_LHU:	mem_ctrlsigs = 4'b0_010;
			`OP_LW :	mem_ctrlsigs = 4'b0_001;
			`OP_SB :	mem_ctrlsigs = 4'b1_100;
			`OP_SH :	mem_ctrlsigs = 4'b1_010;
			`OP_SW :	mem_ctrlsigs = 4'b1_001;
			default:	mem_ctrlsigs = 4'b0_000;
		endcase
	end
endmodule
