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
 *	|- is_UIMM:
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
	input 	wire 			stallD, flushD,
	input  	wire 	[31:0] 	instrD,
	input 	wire	[31:0]	srca2D, srcb2D,
	output 	wire			isBranchNeededD,
	output 	wire			isSaveReg31,		// branch / jump, pc+8=>reg[31]
	output 	wire			isSaveReg,			// branch / jump, pc+8=>reg[rd]
	output 	wire 			pcsrcD, branchD, jumpD,
	output 	wire 			is_UIMM,
	output 	wire 	[1: 0]	HILO_enD,
	output 	wire 			is_dataMovWriteD,	
	output 	wire 			is_dataMovReadD,
	output  wire 			isMulOrDivD,	
	output  wire			isJumpToRegD,
	output 	wire			isJRD, isJALRD,
	output 	wire			isEretD,
	//execute stage
	input 	wire 			stallE, flushE,
	input 	wire	[31:0]	pcE,
	input 	wire	[31:0]	aluoutE,
	input 	wire	[31:0]	writedata_no_duplicateE,
	input 	wire			aluoverflowE,
	input 	wire	[31:0]	cp0causeE,
	input 	wire	[31:0]	cp0statusE,
	output 	wire 			memtoregE, alusrcE,
	output 	wire 			regdstE, regwriteE,	
	output 	wire 	[4:0] 	alucontrolE,
	output 	wire			isDelaySlotInstrE,
	output 	wire 			cp0write_enE,
	output 	wire	[31:0]  exceptionTypeE,
	output 	wire			haveExceptionE,
	output 	wire	[31:0]	badAddrE,
	//mem stage
	input 	wire 			stallM, flushM,
	output 	wire 			memtoregM, 
	output 	wire	[3:0]	memwriteM,
	output 	wire			regwriteM,
	output  wire	[31:0]	writedataM,
	//write back stage
	input 	wire 			stallW, flushW,
	output 	wire 			memtoregW, regwriteW,
	output 	wire	[3:0]	memread_enW,
	output 	wire 			isMemDataReadSignedW
);
	// fetch stage
	wire			isDelaySlotInstrF;
	// decode stage
	wire 			memtoregD, alusrcD,
					regdstD, regwriteD;
	wire	[3:0]	memwriteD, memread_enD;
	wire	[4:0] 	alucontrolD;
	wire			isMemDataReadSignedD;		
	wire 	[3:0]   memInfo_we_bhwD;
	wire			isDelaySlotInstrD;
	wire			isBreakExceptionD, isSyscallExceptionD;
	wire			cp0write_enD;
	wire			retainInstrExceptionD;
	// execute stage
	wire 			isMemDataReadSignedE;	
	wire 	[3:0]   memInfo_we_bhwE;
	wire			isBreakExceptionE, isSyscallExceptionE, isEretE;
	wire 			mbE, mhE, mwE, mweE;
	wire	[3:0]	memwriteE;
	wire 	[3:0]	memread_enE;
	wire 	[31:0]	writedataE;
	wire 			isLoadExceptionE, isStoreExceptionE;
	wire			retainInstrExceptionE;
	wire 	[31:0] 	memAddrE;
	// memory stage
	wire 	[3:0]	memread_enM;
	wire 	[3:0]   memInfo_we_bhwM;
	wire 			isMemDataReadSignedM;	
	wire			isBreakExceptionM, isSyscallExceptionM, isEretM;

	maindec md(
		instrD,
		memtoregD,
		branchD,
		alusrcD,
		regdstD,
		regwriteD,
		jumpD,
		is_UIMM,
		HILO_enD,
		is_dataMovWriteD,
		is_dataMovReadD,
		isMulOrDivD,
		isMemDataReadSignedD,
		memInfo_we_bhwD,
		isJRD, isJALRD,
		isBreakExceptionD, isSyscallExceptionD, isEretD,
		cp0write_enD,
		retainInstrExceptionD
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

	assign memAddrE = aluoutE;

	exceptiondec exceptiondec_example(
		pcE,        // 地址错误，MEM阶段写入异常
		memAddrE,
		cp0causeE,
		cp0statusE,
		isSyscallExceptionE,    // syscall
		isBreakExceptionE,      // break
		isEretE,       // eret
		isLoadExceptionE,       // load addr except
		isStoreExceptionE,      // store addr except
		aluoverflowE,   // overflow exception
		1'b0,  // 中断例外，这里根据ppt提示没有接
		retainInstrExceptionE, // 保留指令例外
		exceptionTypeE,
		haveExceptionE,           // 异常信号
		badAddrE
	);

	assign {mweE, mbE, mhE, mwE} = memInfo_we_bhwE;

	memdec memdec_EXE(
		memAddrE,     
		mweE,        
		mbE, mhE, mwE,       
		writedata_no_duplicateE,
		memwriteE,
		memread_enE,
		writedataE,
		isLoadExceptionE,
		isStoreExceptionE
	);

	// pcsrcD
	assign pcsrcD = branchD & isBranchNeededD;
	assign isDelaySlotInstrF = jumpD | branchD;
	// pipeline registers
	// decode
	flopenrc #(1) regD(
		clk,
		rst,
		~stallD,
		flushD,
		{isDelaySlotInstrF},
		{isDelaySlotInstrD}
	);
	// exec
	flopenrc #(14) regE(
		clk,
		rst,
		~stallE,
		flushE,
		{memtoregD,alusrcD,regdstD,regwriteD,alucontrolD,isMemDataReadSignedD,memInfo_we_bhwD},
		{memtoregE,alusrcE,regdstE,regwriteE,alucontrolE,isMemDataReadSignedE,memInfo_we_bhwE}
	);
	flopenrc #(7) regE_ex(
		clk,
		rst,
		~stallE,
		flushE,
		{retainInstrExceptionD, isDelaySlotInstrD, isSyscallExceptionD, isBreakExceptionD, isEretD, cp0write_enD, isBreakExceptionD},
		{retainInstrExceptionE, isDelaySlotInstrE, isSyscallExceptionE, isBreakExceptionE, isEretE, cp0write_enE, isBreakExceptionE}
	);

	// mem
	flopenrc #(15) regM(
		clk,
		rst,
		~stallM,
		flushM,
		{memtoregE,regwriteE,isMemDataReadSignedE,memInfo_we_bhwE,memwriteE,memread_enE},
		{memtoregM,regwriteM,isMemDataReadSignedM,memInfo_we_bhwM,memwriteM,memread_enM}
	);
	flopenrc #(4) regM_ex(
		clk,
		rst,
		~stallM,
		flushM,
		{isDelaySlotInstrE, isSyscallExceptionE, isBreakExceptionE, isEretE},
		{isDelaySlotInstrM, isSyscallExceptionM, isBreakExceptionM, isEretM}
	);
	flopenrc #(32) regM_memdata(clk, rst, ~stallM, flushM, writedataE, writedataM);
	// writeback
	flopenrc #(7) regW(
		clk,
		rst,
		~stallW,
		flushW,
		{memtoregM,regwriteM,memread_enM,isMemDataReadSignedM},
		{memtoregW,regwriteW,memread_enW,isMemDataReadSignedW}
	);
endmodule