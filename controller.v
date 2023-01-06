`timescale 1ns / 1ps
`include "define_alu_ctrl.vh"
`include "define_inst_dec.vh"
`include "define_bj_control.vh"
/* signal statement
 * -- decode stage
 *  |- opD:
 *	|- functD:
 *	|- pcsrcD:
 *	|- branchD:
 *	|- isBranchNeededD:
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
	input 	wire	[31:0]	srca2D, srcb2D,
	output 	wire			isBranchNeededD,
	output 	wire			isSaveReg31,		// branch / jump, pc+8=>reg[31]
	output 	wire			isSaveReg,			// branch / jump, pc+8=>reg[rd]
	output 	wire 			pcsrcD, branchD, jumpD,
	output 	wire 			is_IMM,
	output 	wire 	[1: 0]	HILO_enD,
	output 	wire 			is_dataMovWriteD,	
	output 	wire 			is_dataMovReadD,
	output  wire 			isMulOrDivD,	
	output  wire			isJumpToRegD,
	//execute stage
	input 	wire 			stallE,
	input 	wire 			flushE,
	output 	wire 			memtoregE, alusrcE,
	output 	wire 			regdstE, regwriteE,	
	output 	wire 	[4:0] 	alucontrolE,
	//mem stage
	input 	wire	[31:0]	aluoutM,
	input 	wire 			stallM,
	input 	wire	[31:0]	writedata_no_duplicateM,
	output 	wire 			memtoregM, 
	output 	wire	[3:0]	memwriteM,
	output 	wire			regwriteM,
	output  wire	[31:0]	writedataM,
	//write back stage
	input 	wire 			stallW,
	output 	wire 			memtoregW, regwriteW,
	output 	wire	[3:0]	memread_enW,
	output 	wire 			isMemDataReadSignedW
);
	//decode stage
	wire 			memtoregD, alusrcD,
					regdstD, regwriteD;
	wire	[3:0]	memwriteD, memread_enD;
	wire	[4:0] 	alucontrolD;
	wire			isMemDataReadSignedD;		
	wire 	[3:0]   memInfo_we_bhwD;
	//execute stage
	wire 			isMemDataReadSignedE;	
	wire 	[3:0]   memInfo_we_bhwE;
	//memory stage
	wire 	[3:0]   memInfo_we_bhwM;
	wire 	[3:0]	memread_enM;
	wire 			isMemDataReadSignedM;	
	wire 			mbM, mhM, mwM, mweM;

	maindec md(
		instrD,
		memtoregD,
		branchD,
		alusrcD,
		regdstD,
		regwriteD,
		jumpD,
		is_IMM,
		HILO_enD,
		is_dataMovWriteD,
		is_dataMovReadD,
		isMulOrDivD,
		isMemDataReadSignedD,
		memInfo_we_bhwD
	);

	aludec ad(
		instrD,
		alucontrolD
	);

	branch_jdec bjdec(
		srca2D, srcb2D,
		instrD,
		isBranchNeededD,
		isSaveReg31,
		isSaveReg,
		isJumpToRegD
	);

	assign {mweM, mbM, mhM, mwM} = memInfo_we_bhwM;

	memdec memdec_Ex(
		aluoutM,     
		mweM,        
		mbM, mhM, mwM,       
		writedata_no_duplicateM,
		memwriteM,
		memread_enM,
		writedataM
	);

	// pcsrcD
	assign pcsrcD = branchD & isBranchNeededD;

	// pipeline registers
	flopenrc #(14) regE(
		clk,
		rst,
		~stallE,
		flushE,
		{memtoregD,alusrcD,regdstD,regwriteD,alucontrolD,isMemDataReadSignedD,memInfo_we_bhwD},
		{memtoregE,alusrcE,regdstE,regwriteE,alucontrolE,isMemDataReadSignedE,memInfo_we_bhwE}
	);
	flopenrc #(7) regM(
		clk,
		rst,
		~stallM,
		1'b0,
		{memtoregE,regwriteE,isMemDataReadSignedE,memInfo_we_bhwE},
		{memtoregM,regwriteM,isMemDataReadSignedM,memInfo_we_bhwM}
	);
	flopenrc #(7) regW(
		clk,
		rst,
		~stallW,
		1'b0,
		{memtoregM,regwriteM,memread_enM,isMemDataReadSignedM},
		{memtoregW,regwriteW,memread_enW,isMemDataReadSignedW}
	);
endmodule