module mycpu_sram (
    input               clk, resetn,            // low active
    input   [5:0]       ext_int,
    output              no_dcache,
    //instr
    output              inst_sram_en,
    output  [3:0]       inst_sram_wen    ,
    output  [31:0]      inst_sram_addr  ,
    output  [31:0]      inst_sram_wdata ,
    input   [31:0]      inst_sram_rdata  , 

    //data
    output              data_sram_en    ,
    output  [3:0]       data_sram_wen    ,
    output  [31:0]      data_sram_addr  ,
    output  [31:0]      data_sram_wdata ,
    input   [31:0]      data_sram_rdata  ,

    //debug _ wb step
    output [31:0]       debug_wb_pc     ,
    output [3:0]        debug_wb_rf_wen  ,
    output [4:0]        debug_wb_rf_wnum ,
    output [31:0]       debug_wb_rf_wdata,

    // ext stall (cache + finding)
    input               instrStall, 
    input               dataStall,
    output              pipelineStall
);
    wire [31: 0] inst_vaddr, inst_paddr, data_vaddr, data_paddr;
    wire [39: 0] ascii;
    assign inst_sram_addr = inst_paddr;
    assign data_sram_addr = data_paddr;

    // sram signal
        // instr
        assign inst_sram_wen = 4'b0000;  
        assign inst_sram_wdata = 32'b0;
        // data
        // debug

    datapath dp(
        .clk(clk),
        .rst(~resetn),
        .ext_int(ext_int),
        .ext_stall(instrStall | dataStall),
        .pipelineStall(pipelineStall),
        // instr
        .sram_inst_en(inst_sram_en),
        .pcF(inst_vaddr),
        .instrF(inst_sram_rdata),
        // data
        .sram_data_en(data_sram_en),
        .memwriteM(data_sram_wen),
        .aluoutM(data_vaddr),
        .writedataM(data_sram_wdata),
        .readdataM(data_sram_rdata),
        // debug - wb
        .debug_pcW(debug_wb_pc),
        .debug_regwriteW(debug_wb_rf_wen),
        .debug_writeregW(debug_wb_rf_wnum),
        .debug_resultW(debug_wb_rf_wdata)
    );

    mmu mmu(
        .inst_vaddr(inst_vaddr),
        .inst_paddr(inst_paddr),
        .data_vaddr(data_vaddr),
        .data_paddr(data_paddr),
        .no_dcache(no_dcache)
    );          // 虚实地址转换模块

    instdec instEx(
        inst_sram_rdata,
        ascii
    );

endmodule

