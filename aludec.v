`timescale 1ns / 1ps
`include "define_alu_ctrl.vh"
`include "define_inst_dec.vh"
module aludec(
	input 	wire	[31:0] 	instrD,
	output 	reg		[4:0] 	alucontrol
    );
	wire [5:0] op, funct;
	assign op = instrD[31:26];
	assign funct = instrD[5:0];
	always @(*) begin
		if (op == `OP_RTYPE) begin		
			// R-type
			case(funct)
				// trap
				`FUNCT_BREAK:  		alucontrol = `SIG_ALU_FAIL;
				`FUNCT_SYSCALL:		alucontrol = `SIG_ALU_FAIL;
				// logic
				`FUNC_AND:	alucontrol = `SIG_ALU_AND 	;
				`FUNC_OR:	alucontrol = `SIG_ALU_OR  	;
				`FUNC_XOR:	alucontrol = `SIG_ALU_XOR 	;
				`FUNC_NOR:	alucontrol = `SIG_ALU_NOR 	;
				// shift
				`FUNC_SLL:	alucontrol = `SIG_ALU_SLL 	;
				`FUNC_SRL :	alucontrol = `SIG_ALU_SRL 	;
				`FUNC_SRA :	alucontrol = `SIG_ALU_SRA 	;
				`FUNC_SLLV:	alucontrol = `SIG_ALU_SLLV	;
				`FUNC_SRLV:	alucontrol = `SIG_ALU_SRLV	;
				`FUNC_SRAV:	alucontrol = `SIG_ALU_SRAV	;
				// data move	
				`FUNC_MFHI:	alucontrol = `SIG_ALU_MFHI	;
				`FUNC_MFLO:	alucontrol = `SIG_ALU_MFLO	;
				// arithmetic
				`FUNC_ADD  :alucontrol = `SIG_ALU_ADD  	;
				`FUNC_ADDU :alucontrol = `SIG_ALU_ADDU 	;
				`FUNC_SUB  :alucontrol = `SIG_ALU_SUB  	;
				`FUNC_SUBU :alucontrol = `SIG_ALU_SUBU 	;
				`FUNC_SLT  :alucontrol = `SIG_ALU_SLT  	;
				`FUNC_SLTU :alucontrol = `SIG_ALU_SLTU 	;
				`FUNC_MULT :alucontrol = `SIG_ALU_MULT 	;
				`FUNC_MULTU:alucontrol = `SIG_ALU_MULTU	;
				`FUNC_DIV  :alucontrol = `SIG_ALU_DIV  	;
				`FUNC_DIVU :alucontrol = `SIG_ALU_DIVU 	;
				// branch and jump
				`FUNC_JALR :alucontrol = `SIG_ALU_PC8	;
				default	   :alucontrol = `SIG_ALU_FAIL 	;
			endcase
		end
		else begin	
			//I-type, J-type
			case (op)
				// logic
				`OP_ANDI:	alucontrol = `SIG_ALU_AND;
				`OP_XORI:	alucontrol = `SIG_ALU_XOR;
				`OP_LUI:	alucontrol = `SIG_ALU_LUI;
				`OP_ORI:	alucontrol = `SIG_ALU_OR;
				// arithmetic
				`OP_ADDI :	alucontrol = `SIG_ALU_ADD;
				`OP_ADDIU:	alucontrol = `SIG_ALU_ADDU;
				`OP_SLTI :	alucontrol = `SIG_ALU_SLT;
				`OP_SLTIU:	alucontrol = `SIG_ALU_SLTU;
				// branch and jump
				`OP_JAL		:	alucontrol = `SIG_ALU_PC8;
				`OP_BLTZAL	:	alucontrol = `SIG_ALU_PC8;
				`OP_BGEZAL	:	alucontrol = `SIG_ALU_PC8;
				// load and store
				`OP_LB 		:	alucontrol = `SIG_ALU_MEM;
				`OP_LBU		:	alucontrol = `SIG_ALU_MEM;
				`OP_LH 		:	alucontrol = `SIG_ALU_MEM;
				`OP_LHU		:	alucontrol = `SIG_ALU_MEM;
				`OP_LW 		:	alucontrol = `SIG_ALU_MEM;
				`OP_SB 		:	alucontrol = `SIG_ALU_MEM;
				`OP_SH 		:	alucontrol = `SIG_ALU_MEM;
				`OP_SW 		:	alucontrol = `SIG_ALU_MEM;
				default:	alucontrol = `SIG_ALU_FAIL; 
			endcase
		end
	end
endmodule
