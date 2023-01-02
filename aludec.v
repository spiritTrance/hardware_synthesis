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
				// logic arithmetic
				`FUNC_AND:	alucontrol = `SIG_ALU_AND ;
				`FUNC_OR:	alucontrol = `SIG_ALU_OR  ;
				`FUNC_XOR:	alucontrol = `SIG_ALU_XOR ;
				`FUNC_NOR:	alucontrol = `SIG_ALU_NOR ;
				// shift arithmetic
				`FUNC_SLL:	alucontrol = `SIG_ALU_SLL ;
				`FUNC_SRL :	alucontrol = `SIG_ALU_SRL ;
				`FUNC_SRA :	alucontrol = `SIG_ALU_SRA ;
				`FUNC_SLLV:	alucontrol = `SIG_ALU_SLLV;
				`FUNC_SRLV:	alucontrol = `SIG_ALU_SRLV;
				`FUNC_SRAV:	alucontrol = `SIG_ALU_SRAV;
				default:	alucontrol = `SIG_ALU_FAIL;
			endcase
		end
		else begin	
			//I-type
			case (op)
				// logic arithmetic
				`OP_ANDI:	alucontrol = `SIG_ALU_AND;
				`OP_XORI:	alucontrol = `SIG_ALU_XOR;
				`OP_LUI:	alucontrol = `SIG_ALU_LUI;
				`OP_ORI:	alucontrol = `SIG_ALU_OR;
				default:	alucontrol = `SIG_ALU_FAIL; 
			endcase
		end
	end
endmodule
