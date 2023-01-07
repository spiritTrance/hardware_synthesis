module exceptiondec(
    input   wire    [31:0]  pcE,        // 地址错误，MEM阶段写入异常
    input   wire    [31:0]  memAddrE,   // 访存地址（数据存储器）
    // exception signal
    input   wire            isSyscallExceptionE,    // syscall
    input   wire            isBreakExceptionE,      // break
    input   wire            isEretExceptionE,       // eret
    input   wire            isLoadExceptionE,       // load addr except
    input   wire            isStoreExceptionE,      // store addr except
    input   wire            isOverflowExceptionE,   // overflow exception
    input   wire            isInterruptExceptionE,  // 中断例外
    input   wire            isRetainedInstructionE, // 保留指令例外
    output  wire    [31:0]  exceptionType,
    output  wire            haveException,          // 异常信号
    output  wire    [31:0]  badAddrE                 
);
    wire isInstrAddrExceptionE; 
    assign isInstrAddrExceptionE = |pcE[1:0];     // 取址地址错误
    // cp0 要写寄存器 只有指令操作即可
    // 用于生成cp0的写入信号
    assign haveException = isSyscallExceptionE | isBreakExceptionE | isLoadExceptionE | isInstrAddrExceptionE |
                           isStoreExceptionE | isOverflowExceptionE | isInterruptExceptionE | isRetainedInstructionE;       // 注意eret不算exception
    assign exceptionType = isInterruptExceptionE    ? 32'h0000_0001 :  // 注意优先级的问题
                           isInstrAddrExceptionE    ? 32'h0000_0004 :
                           isRetainedInstructionE   ? 32'h0000_000a :
                           isOverflowExceptionE     ? 32'h0000_000c :
                        //    isTrapExceptionE         ? 32'h0000_000c :    // 说是没有陷阱例外，省略了
                           isSyscallExceptionE      ? 32'h0000_0008 :
                           isLoadExceptionE         ? 32'h0000_0004 :
                           isStoreExceptionE        ? 32'h0000_0005 :
                           isBreakExceptionE        ? 32'h0000_0009 :                   // 这两行的优先级不知道是啥，但是ref_code的cp0_reg有
                           isEretExceptionE         ? 32'h0000_000e : 32'hffff_ffff ;
    assign badAddrE = ({ 32{ (isLoadExceptionE | isStoreExceptionE) & ~isInstrAddrExceptionE } } & memAddrE)
                      | ({ 32{isInstrAddrExceptionE} } & pcE);
endmodule