`timescale 1ns / 1ps
module hazard(
	// external
	input		extStall,
	output 		instInnerStallFlush,
	output 		dataInnerStallFlush,
	//fetch stage
	output wire stallF, flushF,
	//decode stage
	input wire[4:0] rsD, rtD,
	input wire branchD,
	input wire pcsrcD,
	input wire jumpD,
	input wire isJRD, isJALRD,
	input wire isEretD,
	output wire forwardaD, forwardbD,
	output wire stallD, flushD,
	//execute stage
	input wire[4:0] rsE,rtE,
	input wire[4:0] writeregE,
	input wire regwriteE,
	input wire memtoregE,
	input wire isMulOrDivComputingE,
	input wire haveExceptionE,
	input wire isEretE,
	output reg[1:0] forwardaE,forwardbE,
	output wire stallE, flushE,
	//mem stage
	input wire[4:0] writeregM,
	input wire regwriteM,
	input wire memtoregM,
	output wire stallM, flushM,
	//write back stage
	input wire[4:0] writeregW,
	input wire regwriteW,
	output wire stallW, flushW
    );

	wire lwstallD,branchstallD,jumpstallD;
	//forwarding sources to D stage (branch equality)
	assign forwardaD = (rsD != 0 & rsD == writeregM & regwriteM);
	assign forwardbD = (rtD != 0 & rtD == writeregM & regwriteM);
	
	//forwarding sources to E stage (ALU)

	always @(*) begin
		forwardaE = 2'b00;
		forwardbE = 2'b00;
		if(rsE != 0) begin
			/* code */
			if(rsE == writeregM & regwriteM) begin
				/* code */
				forwardaE = 2'b10;
			end else if(rsE == writeregW & regwriteW) begin
				/* code */
				forwardaE = 2'b01;
			end
		end
		if(rtE != 0) begin
			/* code */
			if(rtE == writeregM & regwriteM) begin
				/* code */
				forwardbE = 2'b10;
			end else if(rtE == writeregW & regwriteW) begin
				/* code */
				forwardbE = 2'b01;
			end
		end
	end

	//stalls
	// 注意lwstall, jumpstall和branchstall都是因为数据冒险产生的
	assign lwstallD = memtoregE & (rtE == rsD | rtE == rtD);			// Ex： lw，Dec：related -> Dec: related, ex: nop, mem: lw
	assign jumpstallD = (isJALRD | isJRD) & 
			(regwriteE & 				// 写寄存器，因为在Ex阶段，branch需要的结果还没算出来
			(writeregE == rsD | writeregE == rtD) |
			memtoregM &					// 读mem，写寄存器，在Mem阶段，branch需要的结果还没从Mem读出来
			(writeregM == rsD | writeregM == rtD));
	assign branchstallD = branchD &
			(regwriteE & 				// 写寄存器，因为在Ex阶段，branch需要的结果还没算出来
			(writeregE == rsD | writeregE == rtD) |
			memtoregM &					// 读mem，写寄存器，在Mem阶段，branch需要的结果还没从Mem读出来
			(writeregM == rsD | writeregM == rtD));

	// stall
	// Ex阶段触发异常/一个特殊的例外是软中断异常，在M阶段触发，原因是出现错误的pc为E阶段/M阶段的
	// 注意haveException，如果前面有异常那后面没必要停了，为啥有flushD，是因为如果stallD了下一拍就把分支指令刷了，而flushD的情况是有异常，没必要等
	assign stallF = extStall | stallD | ((lwstallD | branchstallD | jumpstallD) & ~haveExceptionE);		// 注意这个一停全停的策略可能不正确（主要是对性能有影响），如果是lwstall和branchstall只有F和D要停，改了之后重点检查mul和div，先暂时写在这里
	assign stallD = extStall | stallE | ((lwstallD | branchstallD | jumpstallD) & ~flushD);
	assign stallE = extStall | stallM;
	assign stallM = extStall | stallW;
	assign stallW = extStall | isMulOrDivComputingE;
	// flush
	assign flushF = 1'b0;				// 注意这里是不需要加exception的，因为有问题后，pcnext为32'bf00380(异常处理入口)，而不应该刷新
	assign flushD = haveExceptionE | (isEretD & ~stallE);			// eret没有延迟槽，要刷掉，但前提是前面没有stall，不然Eret上不去
	assign flushE = haveExceptionE | ((lwstallD | branchstallD | jumpstallD) & ~stallE);		// E阶段不停顿，就应该刷掉，防止D阶段的分支指令凑上来搞事，但E停止除外
	assign flushM = haveExceptionE;			// E阶段的信号能检测到所有异常，一般是当前指令有问题，下一阶段MEM要刷掉，特殊情况是软中断，但经过观察，EPC是E阶段的，所以没问题
	assign flushW = 1'b0;
	// ext
	assign instInnerStallFlush = ((lwstallD | branchstallD | jumpstallD) & ~haveExceptionE) | isMulOrDivComputingE | ((lwstallD | branchstallD | jumpstallD) & ~flushD);
	assign dataInnerStallFlush = isMulOrDivComputingE | flushM;
endmodule



// TODO : pcF, hazard, pipeline flush 
// and stall, cp0 write
//hazard: mfc0 $3, cause,($3 <= cause) mtc0 $3, cause (cause <= $3)hazard针对的是通用寄存器