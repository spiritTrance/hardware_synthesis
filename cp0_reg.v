`timescale 1ns / 1ps
`include "defines.vh"

module cp0_reg(
	input 	wire 				clk,
	input 	wire 				rst,

	input 	wire 				we_i,			// 写使能
	input			[4:0] 		waddr_i,		// 写寄存器地址
	input			[4:0] 		raddr_i,		// 读寄存器地址
	input			[`RegBus] 	data_i,			// 写数据

	input 	wire	[5:0] 		int_i,			// 中断标识

	input 	wire	[`RegBus] 	excepttype_i,	// 例外类型，与Cause寄存器有关
	input 	wire	[`RegBus] 	current_inst_addr_i,	// 引发例外的指令地址
	input 	wire	 			is_in_delayslot_i,		// 指令是否在延迟槽，1为在
	input 	wire	[`RegBus] 	bad_addr_i,				// 取指地址或访存地址

	output 	reg		[`RegBus] 	data_o,			// 从CP0寄存器堆读出的数据
	output 	reg		[`RegBus] 	count_o,		// count寄存器
	output 	reg		[`RegBus] 	compare_o,		// 这个只会在一定时候写入
	output 	reg		[`RegBus] 	status_o,		// 寄存器中断状态
	output 	reg		[`RegBus] 	cause_o,		// 引发例外的原因
	output 	reg		[`RegBus] 	epc_o,			// EPC
	output 	reg		[`RegBus] 	config_o,		// 不知道是啥，但是值是固定的
	output 	reg		[`RegBus] 	prid_o,			// 不知道是啥，但是值是固定的
	output 	reg		[`RegBus] 	badvaddr,		// 取指或访存的问题
	output 	reg		 			timer_int_o		// count和compare相同时引发中断
);

	always @(posedge clk) begin		// 注意写是时序逻辑！！！
		if(rst == `RstEnable) begin			// 几个寄存器复位
			count_o <= `ZeroWord;
			compare_o <= `ZeroWord;
			status_o <= 32'b00010000000000000000000000000000;
			cause_o <= `ZeroWord;
			epc_o <= `ZeroWord;
			config_o <= 32'b00000000000000001000000000000000;
			prid_o <= 32'b00000000010011000000000100000010;
			timer_int_o <= `InterruptNotAssert;
		end else begin	// 做两件事：写使能为1时根据寄存器地址写寄存器；有异常时更新异常
			count_o <= count_o + 1;
			cause_o[15:10] <= int_i;			// 中断标识
			if(compare_o != `ZeroWord && count_o == compare_o) begin
				/* code */
				timer_int_o <= `InterruptAssert;
			end
			if(we_i == `WriteEnable) begin	
				/* code */
				case (waddr_i)	// 根据地址写相应的寄存器（写，mtc0啥的）
					`CP0_REG_COUNT:begin 
						count_o <= data_i;
					end
					`CP0_REG_COMPARE:begin 
						compare_o <= data_i;
						timer_int_o <= `InterruptNotAssert;
					end
					`CP0_REG_STATUS:begin 
						status_o <= data_i;
					end
					`CP0_REG_CAUSE:begin 
						cause_o[9:8] <= data_i[9:8];
						cause_o[23] <= data_i[23];
						cause_o[22] <= data_i[22];
					end
					`CP0_REG_EPC:begin 
						epc_o <= data_i;
					end
					default : /* default */;
				endcase
			end

			case (excepttype_i)		// 中断类型，更新EPC和cause_o
				32'h00000001:begin // 中断（其实写入的cause为0）
					if(is_in_delayslot_i == `InDelaySlot) begin
						/* code */
						epc_o <= current_inst_addr_i - 4;
						cause_o[31] <= 1'b1;
					end else begin 
						epc_o <= current_inst_addr_i;
						cause_o[31] <= 1'b0;
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= 5'b00000;
				end
				32'h00000004:begin // 取指非对齐或Load非对齐
					if(is_in_delayslot_i == `InDelaySlot) begin
						/* code */
						epc_o <= current_inst_addr_i - 4;
						cause_o[31] <= 1'b1;
					end else begin 
						epc_o <= current_inst_addr_i;
						cause_o[31] <= 1'b0;
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= 5'b00100;
					badvaddr <= bad_addr_i;
				end
				32'h00000005:begin // Store非对齐
					if(is_in_delayslot_i == `InDelaySlot) begin
						/* code */
						epc_o <= current_inst_addr_i - 4;
						cause_o[31] <= 1'b1;
					end else begin 
						epc_o <= current_inst_addr_i;
						cause_o[31] <= 1'b0;
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= 5'b00101;
					badvaddr <= bad_addr_i;
				end
				32'h00000008:begin // Syscall异常
					if(is_in_delayslot_i == `InDelaySlot) begin
						/* code */
						epc_o <= current_inst_addr_i - 4;
						cause_o[31] <= 1'b1;
					end else begin 
						epc_o <= current_inst_addr_i;
						cause_o[31] <= 1'b0;
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= 5'b01000;
				end
				32'h00000009:begin // BREAK异常
					if(is_in_delayslot_i == `InDelaySlot) begin
						/* code */
						epc_o <= current_inst_addr_i - 4;
						cause_o[31] <= 1'b1;
					end else begin 
						epc_o <= current_inst_addr_i;
						cause_o[31] <= 1'b0;
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= 5'b01001;
				end
				32'h0000000a:begin // 保留指令（译码失败）
					if(is_in_delayslot_i == `InDelaySlot) begin
						/* code */
						epc_o <= current_inst_addr_i - 4;
						cause_o[31] <= 1'b1;
					end else begin 
						epc_o <= current_inst_addr_i;
						cause_o[31] <= 1'b0;
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= 5'b01010;
				end
				32'h0000000c:begin // ALU溢出异常
					if(is_in_delayslot_i == `InDelaySlot) begin
						/* code */
						epc_o <= current_inst_addr_i - 4;
						cause_o[31] <= 1'b1;
					end else begin 
						epc_o <= current_inst_addr_i;
						cause_o[31] <= 1'b0;
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= 5'b01100;
				end
				32'h0000000d:begin // 自陷指令（不在57条中）
					if(is_in_delayslot_i == `InDelaySlot) begin
						/* code */
						epc_o <= current_inst_addr_i - 4;
						cause_o[31] <= 1'b1;
					end else begin 
						epc_o <= current_inst_addr_i;
						cause_o[31] <= 1'b0;
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= 5'b01101;
				end
				32'h0000000e:begin // eret异常（准确说不叫异常，但通过这个在跳转到epc的同时清零status的EXL）
					status_o[1] <= 1'b0;
				end
				default : /* default */;
			endcase
		end
	end

	always @(*) begin		// 输出逻辑
		if(rst == `RstEnable) begin
			/* code */
			data_o <= `ZeroWord;
		end else begin 
			case (raddr_i)
				`CP0_REG_COUNT:begin 
					data_o <= count_o;
				end
				`CP0_REG_COMPARE:begin 
					data_o <= compare_o;
				end
				`CP0_REG_STATUS:begin 
					data_o <= status_o;
				end
				`CP0_REG_CAUSE:begin 
					data_o <= cause_o;
				end
				`CP0_REG_EPC:begin 
					data_o <= epc_o;
				end
				`CP0_REG_PRID:begin 
					data_o <= prid_o;
				end
				`CP0_REG_CONFIG:begin 
					data_o <= config_o;
				end
				`CP0_REG_BADVADDR:begin 
					data_o <= badvaddr;
				end
				default : begin 
					data_o <= `ZeroWord;
				end
			endcase
		end
	
	end
endmodule
