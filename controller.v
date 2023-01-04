`timescale 1ns / 1ps
`include "define_alu_ctrl.vh"
`include "define_inst_dec.vh"
/* signal statement
 * -- decode stage
 *  |- opD:
 *	|- functD:
 *	|- pcsrcD:
 *	|- branchD:
 *	|- equalD:
 *	|- jumpD:
 *	|- is_IMM:
 * -- execute stage:
 *  |- flushE:
 *  |- memtoregE:
 *  |- alusrcE:
 *  |- regdstE: 
 *  |- regwriteE: signal of write to regfile
 *	|- alucontrolE: choose signal for alu
 * -- memory stage:
 *	|- memwriteM: signal of write to data memory
 */
// op = instrD[31:26];
// funct = instrD[5:0];
module controller(
	input 	wire 			clk, rst,
	//decode stage
	input  	wire 	[31:0] 	instrD,
	output 	wire 			pcsrcD, branchD, equalD, jumpD,
	output 	wire 			is_IMM,
	output 	wire 	[1: 0]	HILO_enD,
	output 	wire 			is_dataMovWriteD,	
	output 	wire 			is_dataMovReadD,
	output  wire 			isMulOrDivD,	
	//execute stage
	input 	wire 			stallE,
	input 	wire 			flushE,
	output 	wire 			memtoregE, alusrcE,
	output 	wire 			regdstE, regwriteE,	
	output 	wire 	[4:0] 	alucontrolE,
	//mem stage
	input 	wire 			stallM,
	output 	wire 			memtoregM, memwriteM,
							regwriteM,
	//write back stage
	input 	wire 			stallW,
	output 	wire 			memtoregW, regwriteW
);
	//decode stage
	wire 			memtoregD, memwriteD, alusrcD,
					regdstD, regwriteD;
	wire	[4:0] 	alucontrolD;
	//execute stage
	wire 			memwriteE;

	maindec md(
		instrD,
		memtoregD,
		memwriteD,
		branchD,
		alusrcD,
		regdstD,
		regwriteD,
		jumpD,
		is_IMM,
		HILO_enD,
		is_dataMovWriteD,
		is_dataMovReadD,
		isMulOrDivD
	);

	aludec ad(
		instrD,
		alucontrolD
	);

	assign pcsrcD = branchD & equalD;

	//pipeline registers
	flopenrc #(10) regE(
		clk,
		rst,
		~stallE,
		flushE,
		{memtoregD,memwriteD,alusrcD,regdstD,regwriteD,alucontrolD},
		{memtoregE,memwriteE,alusrcE,regdstE,regwriteE,alucontrolE}
	);
	flopenrc #(8) regM(
		clk,
		rst,
		~stallM,
		1'b0,
		{memtoregE,memwriteE,regwriteE},
		{memtoregM,memwriteM,regwriteM}
	);
	flopenrc #(8) regW(
		clk,
		rst,
		~stallW,
		1'b0,
		{memtoregM,regwriteM},
		{memtoregW,regwriteW}
	);
endmodule