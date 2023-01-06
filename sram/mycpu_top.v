module mycpu_top (
    input clk,resetn,
    input [5:0] ext_int,

    //instr
    output inst_sram_en,
    output [3:0] inst_sram_wen    ,
    output [31:0] inst_sram_addr  ,
    output [31:0] inst_sram_wdata ,
    input [31:0] inst_sram_rdata  , 

    //data
    output data_sram_en,
    output [3:0] data_sram_wen    ,
    output [31:0] data_sram_addr  ,
    output [31:0] data_sram_wdata ,
    input [31:0] data_sram_rdata  ,

    //debug
    output [31:0] debug_wb_pc     ,
    output [3:0] debug_wb_rf_wen  ,
    output [4:0] debug_wb_rf_wnum ,
    output [31:0] debug_wb_rf_wdata
);
    // 参考代码
    // //datapath传出来的信号
    // wire inst_en           ;
    // wire [31:0] inst_vaddr ;
    // wire [31:0] inst_rdata ; 

    // wire data_en           ;
    // wire [31:0] data_vaddr ;
    // wire [31:0] data_rdata ;
    // wire [3:0] data_wen    ;
    // wire [31:0] data_wdata ;
    // wire d_cache_stall     ;

    // wire [31:0] inst_paddr ;
    // wire [31:0] data_paddr ;

    // datapath datapath(
    //     .clk(~clk), .rst(~resetn),  /*时钟取反，因此iram和dram可以当周期取回数据*/
    //     .ext_int(int),
    //     // .ext_int(ext_int),

    //     //inst
    //     .inst_addrF(inst_vaddr),
    //     .inst_enF(inst_en),
    //     .instrF(inst_rdata),

    //     //data
    //     .mem_enM(data_en),              
    //     .mem_addrM(data_vaddr),
    //     .mem_rdataM(data_rdata),
    //     .mem_wenM(data_wen),
    //     .mem_wdataM(data_wdata),

    //     .debug_wb_pc       (debug_wb_pc       ),  
    //     .debug_wb_rf_wen   (debug_wb_rf_wen   ),  
    //     .debug_wb_rf_wnum  (debug_wb_rf_wnum  ),  
    //     .debug_wb_rf_wdata (debug_wb_rf_wdata )  
    // );

    // mmu mmu(
    //     .inst_vaddr(inst_vaddr),
    //     .inst_paddr(inst_paddr),
    //     .data_vaddr(data_vaddr),
    //     .data_paddr(data_paddr)
    // );

    // assign inst_sram_en = inst_en;
    // assign inst_sram_wen = 4'b0;
    // assign inst_sram_addr = inst_paddr;
    // assign inst_sram_wdata = 32'b0;
    // assign inst_rdata = inst_sram_rdata;

    // assign data_sram_en = data_en;
    // assign data_sram_wen = data_wen;
    // assign data_sram_addr = data_paddr;
    // assign data_sram_wdata = data_wdata;
    // assign data_rdata = data_sram_rdata;

endmodule

