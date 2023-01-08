`timescale 1ns / 1ps

module datapath(
	input 	wire 			clk,rst,
	input 			[5:0]	ext_int,
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
	localparam EXCEPT_ADDR = 32'hbfc00380;
	// defination
		// - fetch 
	wire 			flushF, stallF;
		// - FD
	wire 	[31:0] 	pcnextFD_pc4_branch_simplej,pcnextFD,pcplus4F,pcbranchD,instrD,immPCD,pcnextNormalFD;
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
	wire 			isEretD;
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
	wire 			memtoregE, alusrcE, regdstE, regwriteE;
	wire 	[4:0]	alucontrolE;
	wire 	[1:0]	HILO_enE;
	wire			is_dataMovWriteE, is_dataMovReadE;
	wire			isMulOrDivResultOkE, isMulOrDivComputingE;
	wire			flushE, stallE;
	wire 			isMulOrDivE;
	wire 			isSaveReg31E;
	wire 			isSaveRegE;
	wire 	[31:0] 	hi_iE, lo_iE;
	wire			cp0reg_weE;
	wire 	[31:0]	exceptionTypeE;
	wire 	[31:0]	badVaddriE;
	wire	[31:0] 	cp0data_oE;		// cp0的读出数据
	wire			isDelaySlotInstrE;
	wire	[31:0]	writedata_no_duplicate_E;
	wire 			aluoverflowE;	
	wire 			haveExceptionE;
	wire 			isEretE;
		// - mem stage
	wire 			isMulOrDivM;
	wire	[31:0]	pcM;
	wire 	[4:0] 	writeregM;
	wire 	[31:0]	srcaM;			// hilo register needed
	wire 	[31:0] 	hi_oM, lo_oM;	// 不能严格说是M阶段，因为是异步读，准确来说，是ExE阶段读，插进ALU方便数据前推
	wire 	[31:0] 	hi_iM, lo_iM;
	wire 	[1: 0]	HILO_enM;
	wire	[63:0]	alu_HILOM;
	wire			is_dataMovWriteM, is_dataMovReadM;
	wire 			memtoregM, regwriteM;
	wire 	[1: 0]	hilo_we; 
	wire 			flushM, stallM;
	wire 	[31:0]	count_oM, compare_oM, status_oM, cause_oM, epc_oM, config_oM, prid_oM, badvaddrM;	//cp0reg的各种寄存器，还有data_i。需要注意的是，这是异步读，说是M，是因为cp0_reg可以视为在EX/MEM那里的寄存器
	wire 			timer_int_oM;
		// - writeback stage
	wire	[31:0]	pcW;
	wire 	[31:0] 	hi_oW, lo_oW, hilo_ow;
	wire 	[4:0] 	writeregW;
	wire 	[31:0] 	aluoutW, readdataW, readdataExtW, resultW, alu_memResultW;
	wire 	[1: 0]	HILO_enW;
	wire			is_dataMovReadW;
	wire 			memtoregW, regwriteW;
	wire 			flushW, stallW;
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
		stallD, flushD,
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
		isJRD, isJALRD,
		isEretD,
		//execute stage
		stallE, flushE,
		pcE,
		aluoutE,
		writedata_no_duplicate_E,
		aluoverflowE,
		cause_oM,
		status_oM,
		memtoregE, alusrcE,
		regdstE, regwriteE,	
		alucontrolE,
		isDelaySlotInstrE,
		cp0reg_weE,
		exceptionTypeE, 
		haveExceptionE,
		badVaddriE,
		//mem stage
		stallM, flushM,
		memtoregM, 
		memwriteM,
		regwriteM,
		writedataM,
		//write back stage
		stallW, flushW,
		memtoregW, regwriteW,
		memread_enW,
		isMemDataReadSignedW
	);

	// hazard detection
	hazard h(
		//fetch stage
		stallF, flushF,
		//decode stage
		rsD,rtD,
		branchD,
		pcsrcD,
		jumpD,
		isJRD, isJALRD,
		isEretD,
		forwardaD,forwardbD,
		stallD, flushD,
		//execute stage
		rsE,rtE,
		writeregE,
		regwriteE,
		memtoregE,
		isMulOrDivComputingE,
		haveExceptionE,
		isEretE,
		forwardaE,forwardbE,
		stallE, flushE,
		//mem stage
		writeregM,
		regwriteM,
		memtoregM,
		stallM, flushM,
		//write back stage
		writeregW,
		regwriteW,
		stallW, flushW
	);

	// cp0 reg
	cp0_reg cp0Reg(
		clk,
		rst,
		// input
		cp0reg_weE,
		rdE,		// 写寄存器地址
		rdE,		// 读寄存器地址
		srcb2E,			// 写数据

		ext_int,			// 中断标识

		exceptionTypeE,			// 例外类型，与Cause寄存器有关
		pcE,					// 引发例外的指令地址
		isDelaySlotInstrE,		// 指令是否在延迟槽，1为在
		badVaddriE,				// 取指地址或访存地址
		// output
		cp0data_oE,			// 从CP0寄存器堆读出的数据
		count_oM,		// count寄存器
		compare_oM,		// 这个只会在一定时候写入
		status_oM,		// 寄存器中断状态
		cause_oM,		// 引发例外的原因
		epc_oM,			// EPC
		config_oM,		// 不知道是啥，但是值是固定的
		prid_oM,			// 不知道是啥，但是值是固定的
		badvaddrM,		// 取指或访存的问题
		timer_int_oM		// count和compare相同时引发中断
	);

	assign immPCD = { pcplus4D[31: 28], instrD[25: 0], 2'b00 };
	//next PC logic (operates in fetch an decode)
// 	mux2 		#(32) 	pcbrmux		(pcplus4F, pcbranchD, pcsrcD, pcnextbrFD);										// 分支指令地址和 pc + 4 mux
// 	mux2 		#(32) 	pcmux		(pcnextbrFD, { pcplus4D[31: 28], instrD[25: 0], 2'b00 }, jumpD, pcnextFD);		// {pc + 4, branch} 和 j 型指令跳转
	mux3		#(32)	pcmux		(pcplus4F, pcbranchD, immPCD, {jumpD, pcsrcD}, pcnextFD_pc4_branch_simplej);		// 0: pc + 4, 1: branch, 2: jump
	mux2		#(32)	pcmux_jr_F	(pcnextFD_pc4_branch_simplej, srca2D, isJumpToRegD, pcnextNormalFD);		// 正常情况下的pc
	mux3		#(32)	pcmux_except(pcnextNormalFD, EXCEPT_ADDR, epc_oM, {isEretD, haveExceptionE}, pcnextFD);	// 综合正常和异常情况下的pc, 注意异常情况要排除Eret的情况，然后eret是不会动epc的，放心用，但是这里有个问题是不知道有没有异常套异常的情况？理论上没有，因为epc只有一个，异常套异常就别想回去了。
	// regfile (operates in decode and writeback)
	regfile rf(clk, regwriteW, rsD, rtD, writeregW, resultW, srcaD, srcbD);
	// RF - regwriteW is write signal
	// RF - writeregW is address of register
	// RF - resultW is number to write in regFile
	// fetch stage logic
	pc 			#(32) 	pcreg		(clk, rst, ~stallF, pcnextFD, pcF);
	adder 				pcadd1		(pcF,32'b100,pcplus4F);
	// decode stage
	// flopenr 	#(32) 	r1D			(clk, rst, ~stallD, pcplus4F, pcplus4D);
	flopenrc 	#(32) 	r1D			(clk, rst, ~stallD, flushD, pcplus4F, pcplus4D);	// 这里改了一下，不知道有没有bug
	flopenrc 	#(32) 	r2D			(clk, rst, ~stallD, flushD, instrF, instrD);
	flopenrc 	#(32) 	r3D			(clk, rst, ~stallD, flushD, pcF, pcD);				// branch/jump的pc+8计算
	flopenrc 	#(32) 	debug_asciiD(clk, rst, ~stallD, flushD, instrF, instrD);

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
	assign writedata_no_duplicate_E = srcb2E;
	
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
	flopenrc		#(1)	r14E	(clk, rst, ~stallE, flushE, isEretD, isEretE);
	flopenrc 		#(32) 	debug_asciiE 		(clk, rst, ~stallE, flushE, instrD,	instrE);

	mux3 		#(32) 	forwardaemux	(srcaE, resultW, aluoutM, forwardaE, srca2E);
	mux3 		#(32) 	forwardbemux	(srcbE, resultW, aluoutM, forwardbE, srcb2E);	// 数据前推
	mux2 		#(32) 	srcbmux			(srcb2E, signimmE, alusrcE, srcb3E);			// imm选择
	mux2 		#(32) 	srca2Emux		(srca2E, pcE, isSaveRegE, srca3E);		// pc+8逻辑（bj指令）
	alu 				alu				(clk, rst, 
										 srca3E, srcb3E, 
										 alucontrolE, 
										 aluoutE, 
										 saE, 
										 alu_HILO_iE, 
										 cp0data_oE, 
										 flushE, 
										 alu_HILO_oE, 
										 isMulOrDivComputingE, 
										 isMulOrDivResultOkE, 
										 aluoverflowE);
	mux3 		#(5) 	writeregmux		(rtE, rdE, 5'b11111, {isSaveReg31E, regdstE}, writeregE);		// d0, d1, d2
	mux2 		#(32) 	hi_mux			(alu_HILO_oE[63: 32], srca3E, is_dataMovWriteE, hi_iE);			// HILO输入的mux（来自于alu还是寄存器堆），如果是1则来自于寄存器堆，否则来自于alu（乘除法计算结果）
	mux2 		#(32) 	lo_mux			(alu_HILO_oE[31: 0 ], srca3E, is_dataMovWriteE, lo_iE);			// HILO输入的mux（来自于alu还是寄存器堆），如果是1则来自于寄存器堆，否则来自于alu（乘除法计算结果）

	//mem stage
	// TODO: hiloreg clk, M signal or E signal? I think it's E signal instead of M signal, the mux is moved to E stage.
	assign hilo_we = HILO_enE & ({2{is_dataMovWriteE}} | {2{isMulOrDivE}}) & {2{~stallE}};	// 这里可能会加exception的信号，注意下

	hilo_reg 				hiloReg	(clk, rst, hilo_we, hi_iE, lo_iE, hi_oM, lo_oM);

	flopenrc 		#(64) 	r0M		(clk, rst, ~stallM, flushM, {hi_iE, lo_iE}, {hi_iM, lo_iM});
	// flopenrc 		#(32) 	r1M		(clk, rst, ~stallM, flushM, srcb2E, writedata_no_duplicate_M);
	flopenrc 		#(32) 	r2M		(clk, rst, ~stallM, flushM, aluoutE, aluoutM);
	flopenrc 		#(5) 	r3M		(clk, rst, ~stallM, flushM, writeregE, writeregM);
	flopenrc 		#(32) 	r4M		(clk, rst, ~stallM, flushM, srcaE, srcaM);		// For HILO registers
	flopenrc 		#(1) 	r5M		(clk, rst, ~stallM, flushM, is_dataMovReadE, is_dataMovReadM);
	flopenrc 		#(1) 	r6M		(clk, rst, ~stallM, flushM, is_dataMovWriteE, is_dataMovWriteM);
	flopenrc 		#(2) 	r7M		(clk, rst, ~stallM, flushM, HILO_enE, HILO_enM);
	flopenrc 		#(64) 	r8M		(clk, rst, ~stallM, flushM, alu_HILO_oE, alu_HILOM);
	flopenrc 		#(32) 	r9M		(clk, rst, ~stallM, flushM, pcE, pcM);
	flopenrc 		#(1) 	r10M	(clk, rst, ~stallM, flushM, isMulOrDivE, isMulOrDivM);
	flopenrc 		#(32) 	debug_asciiM		(clk, rst, ~stallM, 1'b0, 	instrE, instrM);

	//writeback stage
	flopenrc 		#(32) 	r1W		(clk, rst, ~stallW, flushW, aluoutM, aluoutW);
	flopenrc 		#(32) 	r2W		(clk, rst, ~stallW, flushW, readdataM, readdataW);
	flopenrc 		#(5) 	r3W		(clk, rst, ~stallW, flushW, writeregM, writeregW);
	flopenrc 		#(1) 	r4W		(clk, rst, ~stallW, flushW, is_dataMovReadM, is_dataMovReadW);		// HILO读出数据
	flopenrc 		#(2) 	r5W		(clk, rst, ~stallW, flushW, HILO_enM, HILO_enW);						// HILO使能传递
	flopenrc 		#(32) 	r6W		(clk, rst, ~stallW, flushW, hi_oM, hi_oW);							// hilo结果（注意，这里因为hi_oM是Ex阶段的，涉及到mfhi/mflo可能会引起bug，但是由于hilo不常用，输出很稳定。出问题了再看这里，简单标记一下）
	flopenrc 		#(32) 	r7W		(clk, rst, ~stallW, flushW, lo_oM, lo_oW);							// hilo结果
	flopenrc 		#(32) 	r8W		(clk, rst, ~stallW, flushW, pcM, pcW);							// hilo结果
	flopenrc 		#(32) 	debug_asciiW	(clk, rst, ~stallW, flushW, instrM, instrW);

	memdataReadExtend	memdataReadExt_ex	(readdataW, memread_enW, isMemDataReadSignedW, readdataExtW);	// 从数据存储器读出来的数，根据lb,lh进行处理和扩展

	mux2 		#(32) 	resmux				(aluoutW, readdataExtW, memtoregW, alu_memResultW);			// 原来的mux结果（mem+alu）
	mux2		#(32)	hilomux				(hi_oW, lo_oW, HILO_enW[0], hilo_ow);						// HILO的mux结果，其实这个mux完全没必要，因为读取结果从alu里面出来了，但是不出bug就不修了
	mux2		#(32)	hilo_alu_memmux		(alu_memResultW, hilo_ow, is_dataMovReadW, resultW);		// mem,alu和HI/LO的mux结果
endmodule
