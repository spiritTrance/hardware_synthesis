`timescale 1ns / 1ps

module datapath(
	input 	wire 			clk,rst,
	//fetch stage
	output 	wire	[31:0] 	pcF,
	input 	wire	[31:0] 	instrF,
	//mem stage
	output 	wire			memwriteM,
	output 	wire	[31:0] 	aluoutM, writedataM,
	input 	wire	[31:0] 	readdataM
);
	// defination
		// - fetch stage
	wire stallF;
		// - FD
	wire 	[31:0] 	pcnextFD,pcnextbrFD,pcplus4F,pcbranchD,instrD;
		// - decode stage
	wire 	[31:0] 	pcplus4D;
	wire 			forwardaD, forwardbD;
	wire 	[4:0] 	rsD, rtD, rdD;
	wire 			flushD, stallD; 
	wire 	[31:0] 	signimmD,signimmshD;
	wire 	[31:0] 	srcaD,srca2D,srcbD,srcb2D;
	wire 	[4:0] 	saD;
	wire 			pcsrcD, branchD, jumpD, equalD, is_IMM;
	wire 	[1:0]	HILO_enD;
	wire			is_dataMovWriteD, is_dataMovReadD;		// 注意这个读和写是相对HILO而言的
	wire 			isMulOrDivD;
		// - execute stage
	wire	[1:0] 	forwardaE,forwardbE;
	wire	[4:0] 	rsE,rtE,rdE;
	wire	[4:0] 	writeregE;
	wire	[31:0] 	signimmE;
	wire	[31:0] 	srcaE,srca2E,srcbE,srcb2E,srcb3E;
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
		// - mem stage
	wire 	[4:0] 	writeregM;
	wire 	[31:0]	srcaM;			// hilo register needed
	wire 	[31:0] 	hi_oM, lo_oM;
	wire 	[31:0] 	hi_i, lo_i;
	wire 	[1: 0]	HILO_enM;
	wire	[63:0]	alu_HILOM;
	wire			is_dataMovWriteM, is_dataMovReadM;
	wire 			memtoregM, regwriteM;
	wire 	[1: 0]	hilo_we; 
	wire 			stallM;
		// - writeback stage
	wire 	[31:0] 	hi_oW, lo_oW, hilo_ow;
	wire 	[4:0] 	writeregW;
	wire 	[31:0] 	aluoutW, readdataW, resultW, alu_memResultW;
	wire 	[1: 0]	HILO_enW;
	wire			is_dataMovReadW;
	wire 			memtoregW, regwriteW;
	wire 			stallW;
	// control module
	controller c(
		clk,rst,
		//decode stage
		instrD,
		pcsrcD, branchD, equalD, jumpD,
		is_IMM,
		HILO_enD,
		is_dataMovWriteD,
		is_dataMovReadD,
		isMulOrDivD,
		//execute stage
		stallE,
		flushE,
		memtoregE, alusrcE,
		regdstE, regwriteE,	
		alucontrolE,
		//mem stage
		stallM,
		memtoregM, memwriteM,
		regwriteM,
		//write back stage
		stallW,
		memtoregW, regwriteW
	);

	//hazard detection
	hazard h(
		//fetch stage
		stallF,
		//decode stage
		rsD,rtD,
		branchD,
		forwardaD,forwardbD,
		stallD,
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

	//next PC logic (operates in fetch an decode)
	mux2 		#(32) 	pcbrmux(pcplus4F, pcbranchD, pcsrcD, pcnextbrFD);
	mux2 		#(32) 	pcmux(pcnextbrFD, { pcplus4D[31: 28], instrD[25: 0], 2'b00 }, jumpD, pcnextFD);

	// regfile (operates in decode and writeback)
	regfile rf(clk, regwriteW, rsD, rtD, writeregW, resultW, srcaD, srcbD);
	// RF - regwriteW is write signal
	// RF - writeregW is address of register
	// RF - resultW is number to write in regFile
	// fetch stage logic
	pc 			#(32) 	pcreg(clk,rst,~stallF,pcnextFD,pcF);
	adder 				pcadd1(pcF,32'b100,pcplus4F);
	//decode stage
	flopenr 	#(32) 	r1D			(clk, rst, ~stallD, pcplus4F, pcplus4D);
	flopenrc 	#(32) 	r2D			(clk, rst, ~stallD, flushD, instrF, instrD);
	signext 			se			(instrD[15:0], is_IMM, signimmD);					// 数据扩展
	sl2 				immsh		(signimmD, signimmshD);								// 左移位
	adder 				pcadd2		(pcplus4D, signimmshD, pcbranchD);
	mux2 		#(32) 	forwardamux	(srcaD, aluoutM, forwardaD, srca2D);
	mux2 		#(32) 	forwardbmux	(srcbD, aluoutM, forwardbD, srcb2D);
	eqcmp 				comp		(srca2D, srcb2D, equalD);

	assign rsD = instrD[25:21];
	assign rtD = instrD[20:16];
	assign rdD = instrD[15:11];
	assign saD = instrD[10: 6];

	//execute stage

	assign alu_HILO_iE = {hi_oM, lo_oM};

	flopenrc 		#(32) 	r1E (clk, rst, ~stallE, flushE, srcaD, srcaE);
	flopenrc 		#(32) 	r2E (clk, rst, ~stallE, flushE, srcbD, srcbE);
	flopenrc 		#(32) 	r3E (clk, rst, ~stallE, flushE, signimmD, signimmE);
	flopenrc 		#(5) 	r4E (clk, rst, ~stallE, flushE, rsD, rsE);
	flopenrc 		#(5) 	r5E (clk, rst, ~stallE, flushE, rtD, rtE);
	flopenrc 		#(5) 	r6E (clk, rst, ~stallE, flushE, rdD, rdE);
	flopenrc		#(5)	r7E (clk, rst, ~stallE, flushE, saD, saE);
	flopenrc		#(1)	r8E (clk, rst, ~stallE, flushE, is_dataMovReadD, is_dataMovReadE);
	flopenrc		#(1)	r9E (clk, rst, ~stallE, flushE, is_dataMovWriteD, is_dataMovWriteE);
	flopenrc		#(2)	r10E(clk, rst, ~stallE, flushE, HILO_enD, HILO_enE);
	flopenrc		#(1)	r11E(clk, rst, ~stallE, flushE, isMulOrDivD, isMulOrDivE);

	mux3 		#(32) 	forwardaemux(srcaE, resultW, aluoutM, forwardaE, srca2E);
	mux3 		#(32) 	forwardbemux(srcbE, resultW, aluoutM, forwardbE, srcb2E);
	mux2 		#(32) 	srcbmux(srcb2E, signimmE, alusrcE, srcb3E);
	alu 				alu(clk, rst, srca2E, srcb3E, alucontrolE, aluoutE, saE, alu_HILO_iE, alu_HILO_oE, isMulOrDivComputingE, isMulOrDivResultOkE);
	mux2 		#(5) 	wrmux(rtE, rdE, regdstE, writeregE);
	mux2 		#(32) 	hi_mux(alu_HILO_oE[63: 32], srcaE, is_dataMovWriteE, hi_i);
	mux2 		#(32) 	lo_mux(alu_HILO_oE[31: 0 ], srcaE, is_dataMovWriteE, lo_i);

	//mem stage
	// TODO: hiloreg clk, M signal or E signal? I think it's E signal instead of M signal, the mux is moved to E stage.
	assign hilo_we = HILO_enE & ({2{is_dataMovWriteE}} | {2{isMulOrDivE}}) & {2{~stallE}};	// 这里可能会加stallE的信号，注意下

	hilo_reg 			hiloReg(clk, rst, hilo_we, hi_i, lo_i, hi_oM, lo_oM);

	flopenrc 		#(32) 	r1M(clk, rst, ~stallM, 1'b0, srcb2E, writedataM);
	flopenrc 		#(32) 	r2M(clk, rst, ~stallM, 1'b0, aluoutE, aluoutM);
	flopenrc 		#(5) 	r3M(clk, rst, ~stallM, 1'b0, writeregE, writeregM);
	flopenrc 		#(32) 	r4M(clk, rst, ~stallM, 1'b0, srcaE, srcaM);		// For HILO registers
	flopenrc 		#(1) 	r5M(clk, rst, ~stallM, 1'b0, is_dataMovReadE, is_dataMovReadM);
	flopenrc 		#(1) 	r6M(clk, rst, ~stallM, 1'b0, is_dataMovWriteE, is_dataMovWriteM);
	flopenrc 		#(2) 	r7M(clk, rst, ~stallM, 1'b0, HILO_enE, HILO_enM);
	flopenrc 		#(64) 	r8M(clk, rst, ~stallM, 1'b0, alu_HILO_oE, alu_HILOM);

	//writeback stage
	flopenrc 		#(32) 	r1W(clk, rst, ~stallW, 1'b0, aluoutM, aluoutW);
	flopenrc 		#(32) 	r2W(clk, rst, ~stallW, 1'b0, readdataM, readdataW);
	flopenrc 		#(5) 	r3W(clk, rst, ~stallW, 1'b0, writeregM, writeregW);
	flopenrc 		#(1) 	r4W(clk, rst, ~stallW, 1'b0, is_dataMovReadM, is_dataMovReadW);
	flopenrc 		#(2) 	r5W(clk, rst, ~stallW, 1'b0, HILO_enM, HILO_enW);
	flopenrc 		#(32) 	r6W(clk, rst, ~stallW, 1'b0, hi_oM, hi_oW);
	flopenrc 		#(32) 	r7W(clk, rst, ~stallW, 1'b0, lo_oM, lo_oW);

	mux2 		#(32) 	resmux(aluoutW, readdataW, memtoregW, alu_memResultW);
	mux2		#(32)	hilomux(hi_oW, lo_oW, HILO_enW[0], hilo_ow);
	mux2		#(32)	hilo_alu_memmux(alu_memResultW, hilo_ow, is_dataMovReadW, resultW);
endmodule
