`timescale 1ns / 1ps
module hazard(
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
	assign stallF = stallD | ((lwstallD | branchstallD | jumpstallD) & ~haveExceptionE) | isMulOrDivComputingE;		// 注意这个一停全停的策略可能不正确（主要是对性能有影响），如果是lwstall和branchstall只有F和D要停，改了之后重点检查mul和div，先暂时写在这里
	assign stallD = stallE | ((lwstallD | branchstallD | jumpstallD) & ~flushD) | isMulOrDivComputingE;
	assign stallE = stallM | isMulOrDivComputingE;
	assign stallM = stallW | isMulOrDivComputingE;
	assign stallW = isMulOrDivComputingE;
	// flush
	assign flushF = 1'b0;				// 肯定不能刷，不然指令取不进来
	assign flushD = (isEretD & ~stallE) | haveExceptionE;			// eret没有延迟槽，要刷掉
	assign flushE = ((lwstallD | branchstallD | jumpstallD) & ~isMulOrDivComputingE) | haveExceptionE;
	assign flushM = haveExceptionE;			// E阶段的信号，能够检测到所有异常了，到M的时候应该刷掉
	assign flushW = 1'b0;
endmodule



// TODO : pcF, hazard, pipeline flush 
// and stall, cp0 write
//hazard: mfc0 $3, cause,($3 <= cause) mtc0 $3, cause (cause <= $3)hazard针对的是通用寄存器