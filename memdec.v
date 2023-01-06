module memdec(
    input [31: 0] waddr,        // mem阶段
    input         we,           // 是否为写信号，1为写，0为读
    input         mb, mh, mw,       // byte，half word还是word         
    input [31: 0] writeData_no_Duplicate,   // M阶段的写入数据，因为有写使能的存在，需要重复
    output [3:0]  memwrite_en,
    output [3:0]  memread_en,
    output [31:0] writeData
);
// 用于MEM阶段产生写和读使能信号，以及要写的数据的，放在MEM阶段，放在control模块下面

    wire [1:0] chipSel;
    wire [3:0] byteen, halfen;    // 4位宽的信号
    assign chipSel = waddr[1: 0];
    assign byteen = chipSel[1] ? chipSel[0] ? 4'b1000 :
                                              4'b0100 :
                                 chipSel[0] ? 4'b0010 :
                                              4'b0001 ;
    assign halfen = chipSel[1] ? 4'b1100 : 4'b0011;
    assign memread_en = we ? 4'b0000 :                   // 不读
                        mw ? 4'b1111:                  // 读字
                        mh ? halfen:                  // 读半字
                        mb ? byteen: 4'b0000;                         // 读字节
    assign memwrite_en = ~we ? 4'b0000:              // 不写         
                        mw ? 4'b1111:                  // 写全字     
                        mh ? halfen :                   // 写半字    
                        mb ? byteen : 4'b0000;      
    assign writeData = we ? mw ? writeData_no_Duplicate :
                            mh ? {2{writeData_no_Duplicate[15: 0]}} :
                            mb ? {4{writeData_no_Duplicate[7:0]}} :
                                 writeData_no_Duplicate : 32'b0;     // 写使能但全为0（理论上说不存在的状态）或者不写
endmodule