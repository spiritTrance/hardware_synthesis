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
	input wire clk,rst,
	//decode stage
	input  wire [31:0] instrD,
	output wire pcsrcD,branchD,equalD,jumpD,
	output wire is_IMM,
	//execute stage
	input wire flushE,
	output wire memtoregE,alusrcE,
	output wire regdstE,regwriteE,	
	output wire [4:0] alucontrolE,
	//mem stage
	output wire memtoregM,memwriteM,
				regwriteM,
	//write back stage
	output wire memtoregW,regwriteW

    );
	//decode stage
	wire memtoregD,memwriteD,alusrcD,
		regdstD,regwriteD;
	wire[4:0] alucontrolD;


	//execute stage
	wire memwriteE;

	maindec md(
		instrD,
		memtoregD,
		memwriteD,
		branchD,
		alusrcD,
		regdstD,
		regwriteD,
		jumpD,
		is_IMM
	);

	aludec ad(
		instrD,
		alucontrolD
	);

	assign pcsrcD = branchD & equalD;

	//pipeline registers
	floprc #(8) regE(
		clk,
		rst,
		flushE,
		{memtoregD,memwriteD,alusrcD,regdstD,regwriteD,alucontrolD},
		{memtoregE,memwriteE,alusrcE,regdstE,regwriteE,alucontrolE}
		);
	flopr #(8) regM(
		clk,rst,
		{memtoregE,memwriteE,regwriteE},
		{memtoregM,memwriteM,regwriteM}
		);
	flopr #(8) regW(
		clk,rst,
		{memtoregM,regwriteM},
		{memtoregW,regwriteW}
		);
endmodule