`timescale 1ns / 1ps

module datapath(
	input 	wire 			clk,rst,
	// instr - F
	output 	wire	[31:0] 	pcF,
	input 	wire	[31:0] 	instrF,
	// data - M
	output 	wire	[3:0]	memwriteM,
	output 	wire	[31:0] 	aluoutM, writedataM,
	input 	wire	[31:0] 	readdataM,
	// debug - W
	output 	wire 	[31:0]	debug_pcW,
	output  wire	[3:0]	debug_regwriteW,
	output 	wire 	[4:0]	debug_writeregW,
	output 	wire	[31:0]	debug_resultW
);
	// defination
		// - fetch stage
	wire stallF;
		// - FD
	wire 	[31:0] 	pcnextFD_pc4_branch_simplej,pcnextFD,pcplus4F,pcbranchD,instrD,immPCD;
		// - decode stage
	wire	[31:0]	pcD;
	wire 	[31:0] 	pcplus4D;
	wire 			forwardaD, forwardbD;
	wire 	[4:0] 	rsD, rtD, rdD;
	wire 			flushD, stallD; 
	wire 	[31:0] 	signimmD,signimmshD;
	wire 	[31:0] 	srcaD,srca2D,srcbD,srcb2D;
	wire 	[4:0] 	saD;
	wire 			pcsrcD, branchD, jumpD, isBranchNeededD, is_UIMM;
	wire 	[1:0]	HILO_enD;
	wire			is_dataMovWriteD, is_dataMovReadD;		// 注意这个读和写是相对HILO而言的
	wire 			isMulOrDivD;
	wire 			isSaveReg31D;
	wire 			isSaveRegD;
	wire 			isJumpToRegD;
	wire 			isJRD, isJALRD;
		// - execute stage
	wire	[31:0]	pcE;
	wire	[1:0] 	forwardaE,forwardbE;
	wire	[4:0] 	rsE,rtE,rdE;
	wire	[4:0] 	writeregE;
	wire	[31:0] 	signimmE;
	wire	[31:0] 	srcaE,srca2E,srca3E,srcbE,srcb2E,srcb3E;
	wire	[31:0] 	aluoutE;
	wire	[4:0] 	saE;
	wire	[63:0]	alu_HILO_oE, alu_HILO_iE;
	wire 			memtoregE, alusrcE, regdstE, regwriteE, flushE;
	wire 	[4:0]	alucontrolE;
	wire 	[1:0]	HILO_enE;
	wire			is_dataMovWriteE, is_dataMovReadE;
	wire			isMulOrDivResultOkE, isMulOrDivComputingE;
	wire			stallE;
	wire 			isMulOrDivE;
	wire 			isSaveReg31E;
	wire 			isSaveRegE;
	wire 	[31:0] 	hi_iE, lo_iE;
		// - mem stage
	wire 			isMulOrDivM;
	wire	[31:0]	pcM;
	wire 	[4:0] 	writeregM;
	wire 	[31:0]	srcaM;			// hilo register needed
	wire 	[31:0] 	hi_oM, lo_oM;
	wire 	[31:0] 	hi_iM, lo_iM;
	wire 	[1: 0]	HILO_enM;
	wire	[63:0]	alu_HILOM;
	wire			is_dataMovWriteM, is_dataMovReadM;
	wire 			memtoregM, regwriteM;
	wire 	[1: 0]	hilo_we; 
	wire 			stallM;
	wire	[31:0]	writedata_no_duplicate_M;
		// - writeback stage
	wire	[31:0]	pcW;
	wire 	[31:0] 	hi_oW, lo_oW, hilo_ow;
	wire 	[4:0] 	writeregW;
	wire 	[31:0] 	aluoutW, readdataW, readdataExtW, resultW, alu_memResultW;
	wire 	[1: 0]	HILO_enW;
	wire			is_dataMovReadW;
	wire 			memtoregW, regwriteW;
	wire 			stallW;
	wire 	[3:0] 	memread_enW;
	wire 			isMemDataReadSignedW;

		// debug ascii
	wire	[31:0]	instrE, instrM, instrW;
	wire 	[39:0]	asciiD, asciiE,	asciiM,	asciiW;
	instdec instD(instrD, asciiD);
	instdec instE(instrE, asciiE);
	instdec instM(instrM, asciiM);
	instdec instW(instrW, asciiW);
		// debug assign
	assign debug_pcW = pcW;
	assign debug_regwriteW = {{4{regwriteW}} & ~{4{stallW}}};		// 这里加入stallW是因为 trace 的 sim 原理：如果检测到写入信号，就继续读golden_trace的下一行，实际上停止的时候，很多控制信号应该无效化才合理
	assign debug_writeregW = writeregW;
	assign debug_resultW = resultW;

	// control module
	controller c(
		clk,rst,
		//decode stage
		instrD,
		srca2D, srcb2D,
		isBranchNeededD, 
		isSaveReg31D,
		isSaveRegD,
		pcsrcD, branchD, jumpD,
		is_UIMM,
		HILO_enD,
		is_dataMovWriteD,
		is_dataMovReadD,
		isMulOrDivD,
		isJumpToRegD,
		isJRD,
		isJALRD,
		//execute stage
		stallE,
		flushE,
		memtoregE, alusrcE,
		regdstE, regwriteE,	
		alucontrolE,
		//mem stage
		aluoutM,
		stallM,
		writedata_no_duplicate_M,
		memtoregM, 
		memwriteM,
		regwriteM,
		writedataM,
		//write back stage
		stallW,
		memtoregW, regwriteW,
		memread_enW,
		isMemDataReadSignedW
	);

	//hazard detection
	hazard h(
		//fetch stage
		stallF,
		//decode stage
		rsD,rtD,
		branchD,
		pcsrcD,
		jumpD,
		forwardaD,forwardbD,
		stallD,
		flushD,
		isJRD, isJALRD,
		//execute stage
		rsE,rtE,
		writeregE,
		regwriteE,
		memtoregE,
		isMulOrDivComputingE,
		forwardaE,forwardbE,
		flushE,
		stallE,
		//mem stage
		writeregM,
		regwriteM,
		memtoregM,
		stallM,
		//write back stage
		writeregW,
		regwriteW,
		stallW
	);

	assign immPCD = { pcplus4D[31: 28], instrD[25: 0], 2'b00 };
	//next PC logic (operates in fetch an decode)
// 	mux2 		#(32) 	pcbrmux		(pcplus4F, pcbranchD, pcsrcD, pcnextbrFD);										// 分支指令地址和 pc + 4 mux
// 	mux2 		#(32) 	pcmux		(pcnextbrFD, { pcplus4D[31: 28], instrD[25: 0], 2'b00 }, jumpD, pcnextFD);		// {pc + 4, branch} 和 j 型指令跳转
	mux3		#(32)	pcmux		(pcplus4F, pcbranchD, immPCD, {jumpD, pcsrcD}, pcnextFD_pc4_branch_simplej);		// 0: pc + 4, 1: branch, 2: jump
	mux2		#(32)	pcmux_jr_F	(pcnextFD_pc4_branch_simplej, srca2D, isJumpToRegD, pcnextFD);
	// regfile (operates in decode and writeback)
	regfile rf(clk, regwriteW, rsD, rtD, writeregW, resultW, srcaD, srcbD);
	// RF - regwriteW is write signal
	// RF - writeregW is address of register
	// RF - resultW is number to write in regFile
	// fetch stage logic
	pc 			#(32) 	pcreg		(clk,rst,~stallF,pcnextFD,pcF);
	adder 				pcadd1		(pcF,32'b100,pcplus4F);
	// decode stage
	// flopenr 	#(32) 	r1D			(clk, rst, ~stallD, pcplus4F, pcplus4D);
	flopenrc 	#(32) 	r1D			(clk, rst, ~stallD, flushD, pcplus4F, pcplus4D);	// 这里改了一下，不知道有没有bug
	flopenrc 	#(32) 	r2D			(clk, rst, ~stallD, flushD, instrF, instrD);
	flopenrc 	#(32) 	r3D			(clk, rst, ~stallD, flushD, pcF, pcD);				// branch/jump的pc+8计算
	flopenrc 		#(32) 	debug_asciiD		(clk, rst, ~stallD, flushD, instrF, instrD);

	signext 			se			(instrD[15:0], is_UIMM, signimmD);					// 数据扩展
	sl2 				immsh		(signimmD, signimmshD);								// 左移位
	adder 				pcadd2		(pcplus4D, signimmshD, pcbranchD);
	mux2 		#(32) 	forwardamux	(srcaD, aluoutM, forwardaD, srca2D);
	mux2 		#(32) 	forwardbmux	(srcbD, aluoutM, forwardbD, srcb2D);

	assign rsD = instrD[25:21];
	assign rtD = instrD[20:16];
	assign rdD = instrD[15:11];
	assign saD = instrD[10: 6];

	//execute stage

	assign alu_HILO_iE = {hi_oM, lo_oM};

	flopenrc 		#(32) 	r1E 	(clk, rst, ~stallE, flushE, srcaD, srcaE);
	flopenrc 		#(32) 	r2E 	(clk, rst, ~stallE, flushE, srcbD, srcbE);
	flopenrc 		#(32) 	r3E 	(clk, rst, ~stallE, flushE, signimmD, signimmE);
	flopenrc 		#(5) 	r4E 	(clk, rst, ~stallE, flushE, rsD, rsE);
	flopenrc 		#(5) 	r5E 	(clk, rst, ~stallE, flushE, rtD, rtE);
	flopenrc 		#(5) 	r6E 	(clk, rst, ~stallE, flushE, rdD, rdE);
	flopenrc		#(5)	r7E 	(clk, rst, ~stallE, flushE, saD, saE);
	flopenrc		#(1)	r8E 	(clk, rst, ~stallE, flushE, is_dataMovReadD, is_dataMovReadE);
	flopenrc		#(1)	r9E 	(clk, rst, ~stallE, flushE, is_dataMovWriteD, is_dataMovWriteE);
	flopenrc		#(2)	r10E	(clk, rst, ~stallE, flushE, HILO_enD, HILO_enE);
	flopenrc		#(1)	r11E	(clk, rst, ~stallE, flushE, isMulOrDivD, isMulOrDivE);
	flopenrc		#(32)	r12E	(clk, rst, ~stallE, flushE, pcD, pcE);
	flopenrc		#(2)	r13E	(clk, rst, ~stallE, flushE, {isSaveRegD, isSaveReg31D}, {isSaveRegE, isSaveReg31E});	// pc + 8 逻辑
	flopenrc 		#(32) 	debug_asciiE 		(clk, rst, ~stallE, flushE, instrD,	instrE);

	mux3 		#(32) 	forwardaemux	(srcaE, resultW, aluoutM, forwardaE, srca2E);
	mux3 		#(32) 	forwardbemux	(srcbE, resultW, aluoutM, forwardbE, srcb2E);
	mux2 		#(32) 	srcbmux			(srcb2E, signimmE, alusrcE, srcb3E);
	mux2 		#(32) 	srca2Emux		(srca2E, pcE, isSaveRegE, srca3E);		// pc+8逻辑（bj指令）
	alu 				alu				(clk, rst, srca3E, srcb3E, alucontrolE, aluoutE, saE, alu_HILO_iE, alu_HILO_oE, isMulOrDivComputingE, isMulOrDivResultOkE);
	mux3 		#(5) 	writeregmux		(rtE, rdE, 5'b11111, {isSaveReg31E, regdstE}, writeregE);		// d0, d1, d2
	mux2 		#(32) 	hi_mux			(alu_HILO_oE[63: 32], srca3E, is_dataMovWriteE, hi_iE);			// HILO输入的mux（来自于alu还是寄存器堆），如果是1则来自于寄存器堆，否则来自于alu（乘除法计算结果）
	mux2 		#(32) 	lo_mux			(alu_HILO_oE[31: 0 ], srca3E, is_dataMovWriteE, lo_iE);			// HILO输入的mux（来自于alu还是寄存器堆），如果是1则来自于寄存器堆，否则来自于alu（乘除法计算结果）

	//mem stage
	// TODO: hiloreg clk, M signal or E signal? I think it's E signal instead of M signal, the mux is moved to E stage.
	assign hilo_we = HILO_enM & ({2{is_dataMovWriteM}} | {2{isMulOrDivM}}) & {2{~stallM}};	// 这里可能会加stallE的信号，注意下

	hilo_reg 				hiloReg	(clk, rst, hilo_we, hi_iM, lo_iM, hi_oM, lo_oM);

	flopenrc 		#(64) 	r0M		(clk, rst, ~stallM, 1'b0, {hi_iE, lo_iE}, {hi_iM, lo_iM});
	flopenrc 		#(32) 	r1M		(clk, rst, ~stallM, 1'b0, srcb2E, writedata_no_duplicate_M);
	flopenrc 		#(32) 	r2M		(clk, rst, ~stallM, 1'b0, aluoutE, aluoutM);
	flopenrc 		#(5) 	r3M		(clk, rst, ~stallM, 1'b0, writeregE, writeregM);
	flopenrc 		#(32) 	r4M		(clk, rst, ~stallM, 1'b0, srcaE, srcaM);		// For HILO registers
	flopenrc 		#(1) 	r5M		(clk, rst, ~stallM, 1'b0, is_dataMovReadE, is_dataMovReadM);
	flopenrc 		#(1) 	r6M		(clk, rst, ~stallM, 1'b0, is_dataMovWriteE, is_dataMovWriteM);
	flopenrc 		#(2) 	r7M		(clk, rst, ~stallM, 1'b0, HILO_enE, HILO_enM);
	flopenrc 		#(64) 	r8M		(clk, rst, ~stallM, 1'b0, alu_HILO_oE, alu_HILOM);
	flopenrc 		#(32) 	r9M		(clk, rst, ~stallM, 1'b0, pcE, pcM);
	flopenrc 		#(1) 	r10M	(clk, rst, ~stallM, 1'b0, isMulOrDivE, isMulOrDivM);
	flopenrc 		#(32) 	debug_asciiM		(clk, rst, ~stallM, 1'b0, 	instrE, instrM);

	//writeback stage
	flopenrc 		#(32) 	r1W		(clk, rst, ~stallW, 1'b0, aluoutM, aluoutW);
	flopenrc 		#(32) 	r2W		(clk, rst, ~stallW, 1'b0, readdataM, readdataW);
	flopenrc 		#(5) 	r3W		(clk, rst, ~stallW, 1'b0, writeregM, writeregW);
	flopenrc 		#(1) 	r4W		(clk, rst, ~stallW, 1'b0, is_dataMovReadM, is_dataMovReadW);		// HILO读出数据
	flopenrc 		#(2) 	r5W		(clk, rst, ~stallW, 1'b0, HILO_enM, HILO_enW);						// HILO使能传递
	flopenrc 		#(32) 	r6W		(clk, rst, ~stallW, 1'b0, hi_oM, hi_oW);							// hilo结果
	flopenrc 		#(32) 	r7W		(clk, rst, ~stallW, 1'b0, lo_oM, lo_oW);							// hilo结果
	flopenrc 		#(32) 	r8W		(clk, rst, ~stallW, 1'b0, pcM, pcW);							// hilo结果
	flopenrc 		#(32) 	debug_asciiW	(clk, rst, ~stallW, 1'b0, 	instrM, instrW);

	memdataReadExtend	memdataReadExt_ex	(readdataW, memread_enW, isMemDataReadSignedW, readdataExtW);	// 从数据存储器读出来的数，根据lb,lh进行处理和扩展

	mux2 		#(32) 	resmux				(aluoutW, readdataExtW, memtoregW, alu_memResultW);			// 原来的mux结果（mem+alu）
	mux2		#(32)	hilomux				(hi_oW, lo_oW, HILO_enW[0], hilo_ow);						// HILO的mux结果
	mux2		#(32)	hilo_alu_memmux		(alu_memResultW, hilo_ow, is_dataMovReadW, resultW);		// mem,alu和HI/LO的mux结果
endmodule
