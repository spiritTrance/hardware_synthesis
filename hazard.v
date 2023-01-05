`timescale 1ns / 1ps
module hazard(
	//fetch stage
	output wire stallF,
	//decode stage
	input wire[4:0] rsD, rtD,
	input wire branchD,
	input wire pcsrcD,
	input wire jumpD,
	output wire forwardaD, forwardbD,
	output wire stallD,
	output wire flushD,
	//execute stage
	input wire[4:0] rsE,rtE,
	input wire[4:0] writeregE,
	input wire regwriteE,
	input wire memtoregE,
	input wire isMulOrDivComputingE,
	output reg[1:0] forwardaE,forwardbE,
	output wire flushE,
	output wire stallE,
	//mem stage
	input wire[4:0] writeregM,
	input wire regwriteM,
	input wire memtoregM,
	output wire stallM,
	//write back stage
	input wire[4:0] writeregW,
	input wire regwriteW,
	output wire stallW
    );

	wire lwstallD,branchstallD;

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
	assign lwstallD = memtoregE & (rtE == rsD | rtE == rtD);			// Ex： lw，Dec：related
	assign branchstallD = branchD &
			(regwriteE & 				// 写寄存器，因为在Ex阶段，branch需要的结果还没算出来
			(writeregE == rsD | writeregE == rtD) |
			memtoregM &					// 读mem，写寄存器，在Mem阶段，branch需要的结果还没从Mem读出来
			(writeregM == rsD | writeregM == rtD));
	assign stallF = lwstallD | branchstallD | isMulOrDivComputingE;		// 注意这个一停全停的策略可能不正确（主要是对性能有影响），如果是lwstall和branchstall只有F和D要停，改了之后重点检查mul和div，先暂时写在这里
	assign stallD = lwstallD | branchstallD | isMulOrDivComputingE;
	assign stallE = isMulOrDivComputingE;
	assign stallM = isMulOrDivComputingE;
	assign stallW = isMulOrDivComputingE;
		//stalling D stalls all previous stages
	assign flushE = (lwstallD) & ~isMulOrDivComputingE;
		//stalling D flushes next stage
	assign flushD = 1'b0;			// 不能像默认的通路图那样冲刷，因为MIPS有延迟槽
	// Note: not necessary to stall D stage on store
  	//       if source comes from load;
  	//       instead, another bypass network could
  	//       be added from W to M
endmodule
