`timescale 1ns / 1ps
/*    -------------------------------------
 *    |mycpu_top                          |
 *    |     -------------------------     |
 *    |     |mycpu-sram             |     |
 *    |     |   ----------  -----   |     |
 *    |     |   |datapath|--|mmu|   |     |
 *    |     |   ----------  -----   |     |
 *    |     -------------------------     |
 *    |          |    sram     |          |
 *    |     -------------------------     |
 *    |     |   sram - sram like    |     |
 *    |     -------------------------     |
 *    |          |  sram-like  |          |
 *    |     -----------    ----------     |
 *    |     | icache  |    | dcache |     |
 *    |     -----------    ----------     |
 *    |          |  sram-like  |          |
 *    |     -------------------------     |
 *    |     |   cpu-axi interface   |     |
 *    |     -------------------------     |
 *    |          |     axi     |          |
 *    -----------|-------------|-----------
 *               |             |
 *                          
 *///显然，从这个接口来说这个模块是master
module mycpu_top(
    
    input   wire    [5:0]   ext_int,   //high active

    input   wire            aclk,
    input   wire            aresetn,   //low active     aresetn: low active, rstn: high active
    // axi
    //ar
    output  wire    [3 :0]  arid         ,
    output  wire    [31:0]  araddr       ,
    output  wire    [7 :0]  arlen        ,
    output  wire    [2 :0]  arsize       ,
    output  wire    [1 :0]  arburst      ,
    output  wire    [1 :0]  arlock       ,
    output  wire    [3 :0]  arcache      ,
    output  wire    [2 :0]  arprot       ,
    output  wire            arvalid      ,
    input   wire            arready      ,
    //r           
    input   wire    [3 :0]  rid          ,
    input   wire    [31:0]  rdata        ,
    input   wire    [1 :0]  rresp        ,
    input   wire            rlast        ,
    input   wire            rvalid       ,
    output  wire            rready       ,
    //aw          
    output  wire    [3 :0]  awid         ,
    output  wire    [31:0]  awaddr       ,
    output  wire    [7 :0]  awlen        ,
    output  wire    [2 :0]  awsize       ,
    output  wire    [1 :0]  awburst      ,
    output  wire    [1 :0]  awlock       ,
    output  wire    [3 :0]  awcache      ,
    output  wire    [2 :0]  awprot       ,
    output  wire            awvalid      ,
    input   wire            awready      ,
    //w          
    output  wire    [3 :0]  wid          ,
    output  wire    [31:0]  wdata        ,
    output  wire    [3 :0]  wstrb        ,
    output  wire            wlast        ,
    output  wire            wvalid       ,
    input   wire            wready       ,
    //b           
    input   wire    [3 :0]  bid          ,
    input   wire    [1 :0]  bresp        ,
    input   wire            bvalid       ,
    output  wire            bready       ,
    //debug interface
    output  wire    [31:0]  debug_wb_pc      ,
    output  wire    [3:0]   debug_wb_rf_wen  ,
    output  wire    [4:0]   debug_wb_rf_wnum ,
    output  wire    [31:0]  debug_wb_rf_wdata
);

    assign rst = ~aresetn;
    assign clk = aclk;
    // cpu_sram
        // instr - sram
            wire                inst_sram_en        ;
            wire    [3:0]       inst_sram_wen       ;
            wire    [31:0]      inst_sram_addr      ;
            wire    [31:0]      inst_sram_wdata     ;
            wire    [31:0]      inst_sram_rdata     ;

        // data - sram
            wire                data_sram_en        ;
            wire    [3:0]       data_sram_wen       ;
            wire    [31:0]      data_sram_addr      ;
            wire    [31:0]      data_sram_wdata     ;
            wire    [31:0]      data_sram_rdata     ;

    // sram - sram like
            wire                stallData, stallInst, pipelineStall;

    // cpu - axi interface
        //inst sram-like 
            wire                inst_req     ;
            wire                inst_wr      ;
            wire    [1 :0]      inst_size    ;
            wire    [31:0]      inst_addr    ;
            wire    [31:0]      inst_wdata   ;
            wire    [31:0]      inst_rdata   ;
            wire                inst_addr_ok ;
            wire                inst_data_ok ;
        //data sram-like 
            wire                data_req     ;
            wire                data_wr      ;
            wire    [1 :0]      data_size    ;
            wire    [31:0]      data_addr    ;
            wire    [31:0]      data_wdata   ;
            wire    [31:0]      data_rdata   ;
            wire                data_addr_ok ;
            wire                data_data_ok ;

    mycpu_sram sram_cpu(
        .clk(clk), .resetn(aresetn),
        .ext_int(ext_int),
        //instr
        .inst_sram_en(inst_sram_en),
        .inst_sram_wen(inst_sram_wen),
        .inst_sram_addr(inst_sram_addr), 
        .inst_sram_wdata(inst_sram_wdata),
        .inst_sram_rdata(inst_sram_rdata),  
        //data
        .data_sram_en(data_sram_en),
        .data_sram_wen(data_sram_wen),
        .data_sram_addr(data_sram_addr),
        .data_sram_wdata(data_sram_wdata),
        .data_sram_rdata(data_sram_rdata),
        //debug _ wb step
        .debug_wb_pc(debug_wb_pc),
        .debug_wb_rf_wen(debug_wb_rf_wen),
        .debug_wb_rf_wnum(debug_wb_rf_wnum),
        .debug_wb_rf_wdata( debug_wb_rf_wdata),
        // cache stall
        .instrStall(stallInst),
        .dataStall(stallData),
        .pipelineStall(pipelineStall)
    );

    sram_to_sram_like inst_sram2sramlike(
        .clk(clk), .areset(aresetn),    // high active
        // sram
        .s_en(inst_sram_en),
        .s_we(inst_sram_wen),
        .s_addr(inst_sram_addr),
        .s_wdata(inst_sram_wdata),
        .s_rdata(inst_sram_rdata),
        // sram - like
        .sl_req(inst_req),
        .sl_wr(inst_wr),
        .sl_size(inst_size),
        .sl_addr(inst_addr),
        .sl_wdata(inst_wdata),
        .sl_rdata(inst_rdata),
        .sl_addr_ok(inst_addr_ok),
        .sl_data_ok(inst_data_ok),
        // signal to cpu
        .pipelineStall(pipelineStall),
        .stall(stallInst)
    );

    sram_to_sram_like data_sram2sramlike(
        .clk(clk), .areset(aresetn),    // high active
        // sram
        .s_en(data_sram_en),
        .s_we(data_sram_wen),
        .s_addr(data_sram_addr),
        .s_wdata(data_sram_wdata),
        .s_rdata(data_sram_rdata),
        // sram - like
        .sl_req(data_req),
        .sl_wr(data_wr),
        .sl_size(data_size),
        .sl_addr(data_addr),
        .sl_wdata(data_wdata),
        .sl_rdata(data_rdata),
        .sl_addr_ok(data_addr_ok),
        .sl_data_ok(data_data_ok),
        // signal to cpu
        .pipelineStall(pipelineStall),
        .stall(stallData)
    );

    cpu_axi_interface sram_like_2_axi_example
    (
            .clk(clk)                   ,
            .resetn(aresetn)            , 
        //inst sram-like 
            .inst_req(inst_req)         ,
            .inst_wr(inst_wr)           ,
            .inst_size(inst_size)       ,
            .inst_addr(inst_addr)       ,
            .inst_wdata(inst_wdata)     ,
            .inst_rdata(inst_rdata)     ,
            .inst_addr_ok(inst_addr_ok) ,
            .inst_data_ok(inst_data_ok) ,
        //data sram-like 
            .data_req(data_req)         ,
            .data_wr(data_wr)           ,
            .data_size(data_size)       ,
            .data_addr(data_addr)       ,
            .data_wdata(data_wdata)     ,
            .data_rdata(data_rdata)     ,
            .data_addr_ok(data_addr_ok) ,
            .data_data_ok(data_data_ok) ,
        //axi
        //ar
            .arid(arid)             ,
            .araddr(araddr)         ,
            .arlen(arlen)           ,
            .arsize(arsize)         ,
            .arburst(arburst)       ,
            .arlock(arlock)         ,
            .arcache(arcache)       ,
            .arprot(arprot)         ,
            .arvalid(arvalid)       ,
            .arready(arready)       ,
        //r           
            .rid(rid)               ,
            .rdata(rdata)           ,
            .rresp(rresp)           ,
            .rlast(rlast)           ,
            .rvalid(rvalid)         ,
            .rready(rready)         ,
        //aw          
            .awid(awid)             ,
            .awaddr(awaddr)         ,
            .awlen(awlen)           ,
            .awsize(awsize)         ,
            .awburst(awburst)       ,
            .awlock(awlock)         ,
            .awcache(awcache)       ,
            .awprot(awprot)         ,
            .awvalid(awvalid)       ,
            .awready(awready)       ,
        //w          
            .wid(wid)               ,
            .wdata(wdata)           ,
            .wstrb(wstrb)           ,
            .wlast(wlast)           ,
            .wvalid(wvalid)         ,
            .wready(wready)         ,
        //b           
            .bid(bid)               ,
            .bresp(bresp)           ,
            .bvalid(bvalid)         ,
            .bready(bready)       
    );

endmodule