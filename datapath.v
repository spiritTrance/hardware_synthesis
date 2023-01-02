`timescale 1ns / 1ps

module datapath(
	input 	wire 			clk,rst,
	//fetch stage
	output 	wire	[31:0] 	pcF,
	input 	wire	[31:0] 	instrF,
	//mem stage
	output 	wire			memwriteM,
	output 	wire	[31:0] 	aluoutM,writedataM,
	input 	wire	[31:0] 	readdataM
);
	// defination
		// - fetch stage
	wire stallF;
		// - FD
	wire [31:0] pcnextFD,pcnextbrFD,pcplus4F,pcbranchD,instrD;
		// - decode stage
	wire [31:0] pcplus4D;
	wire forwardaD, forwardbD;
	wire [4:0] rsD, rtD, rdD;
	wire flushD, stallD; 
	wire [31:0] signimmD,signimmshD;
	wire [31:0] srcaD,srca2D,srcbD,srcb2D;
	wire [4:0] 	saD;
	wire pcsrcD, branchD, jumpD, equalD, is_IMM;
		// - execute stage
	wire [1:0] 	forwardaE,forwardbE;
	wire [4:0] 	rsE,rtE,rdE;
	wire [4:0] 	writeregE;
	wire [31:0] signimmE;
	wire [31:0] srcaE,srca2E,srcbE,srcb2E,srcb3E;
	wire [31:0] aluoutE;
	wire [4:0] 	saE;
	wire [63:0]	alu_HILO;
	wire memtoregE, alusrcE, regdstE, regwriteE, flushE;
	wire [4:0]	alucontrolE;
		// - mem stage
	wire [4:0] 	writeregM;
	wire 		hilo_weM;
	wire [31:0] hi_oM, lo_oM;
	wire [31:0] hi_i,  lo_i;
	wire 		memtoregM, regwriteM;
		// - writeback stage
	wire [4:0] writeregW;
	wire [31:0] aluoutW,readdataW,resultW;
	wire memtoregW, regwriteW;

	// control module
	controller c(
		clk,rst,
		//decode stage
		instrD,
		pcsrcD,branchD,equalD,jumpD,
		is_IMM,
		//execute stage
		flushE,
		memtoregE,alusrcE,
		regdstE,regwriteE,	
		alucontrolE,
		//mem stage
		memtoregM,memwriteM,
		regwriteM,
		//write back stage
		memtoregW,regwriteW
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
		forwardaE,forwardbE,
		flushE,
		//mem stage
		writeregM,
		regwriteM,
		memtoregM,
		//write back stage
		writeregW,
		regwriteW
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

	floprc 		#(32) 	r1E(clk, rst, flushE, srcaD, srcaE);
	floprc 		#(32) 	r2E(clk, rst, flushE, srcbD, srcbE);
	floprc 		#(32) 	r3E(clk, rst, flushE, signimmD, signimmE);
	floprc 		#(5) 	r4E(clk, rst, flushE, rsD, rsE);
	floprc 		#(5) 	r5E(clk, rst, flushE, rtD, rtE);
	floprc 		#(5) 	r6E(clk, rst, flushE, rdD, rdE);
	floprc		#(5)	r7E(clk, rst, flushE, saD, saE);

	mux3 		#(32) 	forwardaemux(srcaE, resultW, aluoutM, forwardaE, srca2E);
	mux3 		#(32) 	forwardbemux(srcbE, resultW, aluoutM, forwardbE, srcb2E);
	mux2 		#(32) 	srcbmux(srcb2E, signimmE, alusrcE, srcb3E);
	alu 				alu(srca2E, srcb3E, alucontrolE, aluoutE, saE, alu_HILO);
	mux2 		#(5) 	wrmux(rtE, rdE, regdstE, writeregE);

	//mem stage

	assign {hi_i, lo_i} = aluoutM;			// HI, LO concatenate

	flopr 		#(32) 	r1M(clk, rst, srcb2E, writedataM);
	flopr 		#(32) 	r2M(clk, rst, aluoutE, aluoutM);
	flopr 		#(5) 	r3M(clk, rst, writeregE, writeregM);
	hilo_reg 			hiloReg(clk, rst, we, hi_i, lo_i, hi_oM, lo_oM);

	assign alu_HILO = {hi_oM, lo_oM};

	//writeback stage
	flopr 		#(32) 	r1W(clk, rst, aluoutM, aluoutW);
	flopr 		#(32) 	r2W(clk, rst, readdataM, readdataW);
	flopr 		#(5) 	r3W(clk, rst, writeregM, writeregW);
	mux2 		#(32) 	resmux(aluoutW, readdataW, memtoregW, resultW);
endmodule
