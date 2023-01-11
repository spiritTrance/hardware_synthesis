`timescale 1ns / 1ps
/*    ---------------------------------------------------------------------
 *    |mycpu_top                                                          |
 *    |                     -------------------------                     |
 *    |                     |mycpu-sram             |                     |
 *    |                     |  ----------     ----- |                     |
 *    |                     |  |datapath|     |mmu|-|-----------          |
 *    |                     |  ----------     ----- |   |      |          |
 *    |                     -------------------------   |      |          |
 *    |                           | sram      |         |      |          |
 *    |                           |cpu        |cpu      |      |          |
 *    |                     -------------------------   |      |          |
 *    |                     |   sram - sram like    |   |      |          |
 *    |                     -------------------------   |      |          |
 *    |                         |   sram-like |cpu      |      |          |
 *    |                         |         -----------------    |          |
 *    |                         |         |  bridge 1*2   |    |          |
 *    |                         |         -----------------    |          |
 *    |                         |   sram-like  |ram     |conf  |          |
 *    |                         |cpu           |        |      |          |
 *    |                     -----------    ----------   |      |          |
 *    |                     | icache  |    | dcache |   |      |          |
 *    |                     -----------    ----------   |      |          |
 *    |                          |  sram-like  |        |      |          |
 *    |                          |             |cache   |      |          |
 *    |                          |        -----------------    |          |
 *    |                          |        |  bridge 2*1   |-----          |
 *    |                          |        -----------------               |
 *    |                     cache|   sram-like |warp                      |
 *    |                     -------------------------                     |
 *    |                     |   cpu-axi interface   |                     |
 *    |                     -------------------------                     |
 *    |                          |     axi     |                          |
 *    ---------------------------|-------------|---------------------------
 *                               |             |
 *                          
 *///显然，从这个接口来说这个模块是master
module mycpu_top(
    // control
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
        // signal
            wire                no_dcache           ;
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

    // sram - like interface
        //inst sram-like 
            wire                cpu_inst_req     ;
            wire                cpu_inst_wr      ;
            wire    [1 :0]      cpu_inst_size    ;
            wire    [31:0]      cpu_inst_addr    ;
            wire    [31:0]      cpu_inst_wdata   ;
            wire    [31:0]      cpu_inst_rdata   ;
            wire                cpu_inst_addr_ok ;
            wire                cpu_inst_data_ok ;
        //data sram-like 
            wire                cpu_data_req     ;
            wire                cpu_data_wr      ;
            wire    [1 :0]      cpu_data_size    ;
            wire    [31:0]      cpu_data_addr    ;
            wire    [31:0]      cpu_data_wdata   ;
            wire    [31:0]      cpu_data_rdata   ;
            wire                cpu_data_addr_ok ;
            wire                cpu_data_data_ok ;

    // cache - axi interface
        // i - cache
        wire            cache_inst_req     ;
        wire            cache_inst_wr      ;
        wire    [1 :0]  cache_inst_size    ;
        wire    [31:0]  cache_inst_addr    ;
        wire    [31:0]  cache_inst_wdata   ;
        wire    [31:0]  cache_inst_rdata   ;
        wire            cache_inst_addr_ok ;         // axi接收到地址
        wire            cache_inst_data_ok ;         // 返回了data
        // d - cache
        wire            cache_data_req      ;
        wire            cache_data_wr       ;
        wire    [1 :0]  cache_data_size     ;
        wire    [31:0]  cache_data_addr     ;
        wire    [31:0]  cache_data_wdata    ;
        wire    [31:0]  cache_data_rdata    ;
        wire            cache_data_addr_ok  ;
        wire            cache_data_data_ok  ;
        
    // 1*2 bridge - dcache
        // ram (cache optional)
            wire          ram_data_req        ;
            wire          ram_data_wr         ;
            wire  [1 :0]  ram_data_size       ;
            wire  [31:0]  ram_data_addr       ;
            wire  [31:0]  ram_data_wdata      ;
            wire  [31:0]  ram_data_rdata      ;
            wire          ram_data_addr_ok    ;
            wire          ram_data_data_ok    ;
        // confreg
            wire          conf_data_req       ;
            wire          conf_data_wr        ;
            wire  [1 :0]  conf_data_size      ;
            wire  [31:0]  conf_data_addr      ;
            wire  [31:0]  conf_data_wdata     ;
            wire  [31:0]  conf_data_rdata     ;
            wire          conf_data_addr_ok   ;
            wire          conf_data_data_ok   ;

    // 2*1 bridge - dcache
        // wrap
            wire        wrap_data_req         ;
            wire        wrap_data_wr          ;
            wire [1 :0] wrap_data_size        ;
            wire [31:0] wrap_data_addr        ;
            wire [31:0] wrap_data_wdata       ;
            wire [31:0] wrap_data_rdata       ;
            wire        wrap_data_addr_ok     ;
            wire        wrap_data_data_ok     ;

    mycpu_sram sram_cpu(
        .clk(clk), .resetn(aresetn),
        .ext_int(ext_int),
        .no_dcache(no_dcache),
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
        .sl_req(cpu_inst_req),
        .sl_wr(cpu_inst_wr),
        .sl_size(cpu_inst_size),
        .sl_addr(cpu_inst_addr),
        .sl_wdata(cpu_inst_wdata),
        .sl_rdata(cpu_inst_rdata),
        .sl_addr_ok(cpu_inst_addr_ok),
        .sl_data_ok(cpu_inst_data_ok),
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
        .sl_req(cpu_data_req),
        .sl_wr(cpu_data_wr),
        .sl_size(cpu_data_size),
        .sl_addr(cpu_data_addr),
        .sl_wdata(cpu_data_wdata),
        .sl_rdata(cpu_data_rdata),
        .sl_addr_ok(cpu_data_addr_ok),
        .sl_data_ok(cpu_data_data_ok),
        // signal to cpu
        .pipelineStall(pipelineStall),
        .stall(stallData)
    );

    bridge_1_2 d_bridge_1_2(
        .no_dcache(no_dcache),
        // cpu
        .cpu_req            (cpu_data_req),
        .cpu_wr             (cpu_data_wr),
        .cpu_size           (cpu_data_size),
        .cpu_addr           (cpu_data_addr),
        .cpu_wdata          (cpu_data_wdata),
        .cpu_rdata          (cpu_data_rdata),
        .cpu_addr_ok        (cpu_data_addr_ok),
        .cpu_data_ok        (cpu_data_data_ok),
        // ram (cache optional)
        .ram_req            (ram_data_req    )                  ,
        .ram_wr             (ram_data_wr     )                  ,
        .ram_size           (ram_data_size   )                  ,
        .ram_addr           (ram_data_addr   )                  ,
        .ram_wdata          (ram_data_wdata  )                  ,
        .ram_rdata          (ram_data_rdata  )                  ,
        .ram_addr_ok        (ram_data_addr_ok)                  ,
        .ram_data_ok        (ram_data_data_ok)                  ,
        // confreg
        .conf_req           (conf_data_req    )                ,
        .conf_wr            (conf_data_wr     )                 ,
        .conf_size          (conf_data_size   )               ,
        .conf_addr          (conf_data_addr   )               ,
        .conf_wdata         (conf_data_wdata  )              ,
        .conf_rdata         (conf_data_rdata  )              ,
        .conf_addr_ok       (conf_data_addr_ok)                ,
        .conf_data_ok       (conf_data_data_ok)                
    );

    i_cache iCache(
        .clk(clk), .rst(rst),
        //mips core
        .cpu_inst_req       (cpu_inst_req)         ,
        .cpu_inst_wr        (cpu_inst_wr)           ,
        .cpu_inst_size      (cpu_inst_size)       ,
        .cpu_inst_addr      (cpu_inst_addr)       ,
        .cpu_inst_wdata     (cpu_inst_wdata)     ,
        .cpu_inst_rdata     (cpu_inst_rdata)     ,
        .cpu_inst_addr_ok   (cpu_inst_addr_ok) ,
        .cpu_inst_data_ok   (cpu_inst_data_ok) ,

        //axi interface
        .cache_inst_req     (cache_inst_req)         ,
        .cache_inst_wr      (cache_inst_wr)           ,
        .cache_inst_size    (cache_inst_size)       ,
        .cache_inst_addr    (cache_inst_addr)       ,
        .cache_inst_wdata   (cache_inst_wdata)     ,
        .cache_inst_rdata   (cache_inst_rdata)     ,
        .cache_inst_addr_ok (cache_inst_addr_ok) ,         // axi接收到地址
        .cache_inst_data_ok (cache_inst_data_ok)           // 返回了data
    );
    d_cache dCache(
        .clk(clk), .rst(rst),
        //mips core
        .cpu_data_req       (ram_data_req)     ,
        .cpu_data_wr        (ram_data_wr)      ,
        .cpu_data_size      (ram_data_size)    ,
        .cpu_data_addr      (ram_data_addr)    ,
        .cpu_data_wdata     (ram_data_wdata)   ,
        .cpu_data_rdata     (ram_data_rdata)   ,
        .cpu_data_addr_ok   (ram_data_addr_ok) ,
        .cpu_data_data_ok   (ram_data_data_ok) ,

        //axi interface (to bridge 2*1)
        .cache_data_req     (cache_data_req)     ,
        .cache_data_wr      (cache_data_wr)      ,
        .cache_data_size    (cache_data_size)    ,
        .cache_data_addr    (cache_data_addr)    ,
        .cache_data_wdata   (cache_data_wdata)   ,
        .cache_data_rdata   (cache_data_rdata)   ,
        .cache_data_addr_ok (cache_data_addr_ok) ,
        .cache_data_data_ok (cache_data_data_ok) 
    );

    bridge_2_1 d_bridge_2_1(
        .no_dcache(no_dcache),
        // ram
        .ram_req      (cache_data_req)           ,
        .ram_wr       (cache_data_wr)         ,
        .ram_size     (cache_data_size)         ,
        .ram_addr     (cache_data_addr)         ,
        .ram_wdata    (cache_data_wdata)       ,
        .ram_rdata    (cache_data_rdata)       ,
        .ram_addr_ok  (cache_data_addr_ok)       ,
        .ram_data_ok  (cache_data_data_ok)       ,
        // conf
        .conf_req     (conf_data_req    )            ,
        .conf_wr      (conf_data_wr     )            ,
        .conf_size    (conf_data_size   )            ,
        .conf_addr    (conf_data_addr   )            ,
        .conf_wdata   (conf_data_wdata  )            ,
        .conf_rdata   (conf_data_rdata  )            ,
        .conf_addr_ok (conf_data_addr_ok)            ,
        .conf_data_ok (conf_data_data_ok)            ,
        // wrap
        .wrap_req       (wrap_data_req    ) ,
        .wrap_wr        (wrap_data_wr     ) ,
        .wrap_size      (wrap_data_size   ) ,
        .wrap_addr      (wrap_data_addr   ) ,
        .wrap_wdata     (wrap_data_wdata  ) ,
        .wrap_rdata     (wrap_data_rdata  ) ,
        .wrap_addr_ok   (wrap_data_addr_ok) ,
        .wrap_data_ok   (wrap_data_data_ok)
    );

    cpu_axi_interface sram_like_2_axi_example(
            .clk(clk)                   ,
            .resetn(aresetn)            , 
        //inst sram-like 
            .inst_req       (cache_inst_req)         ,
            .inst_wr        (cache_inst_wr)           ,
            .inst_size      (cache_inst_size)       ,
            .inst_addr      (cache_inst_addr)       ,
            .inst_wdata     (cache_inst_wdata)     ,
            .inst_rdata     (cache_inst_rdata)     ,
            .inst_addr_ok   (cache_inst_addr_ok) ,
            .inst_data_ok   (cache_inst_data_ok) ,
        //data sram-like 
            .data_req       (wrap_data_req    )     ,
            .data_wr        (wrap_data_wr     )      ,
            .data_size      (wrap_data_size   )    ,
            .data_addr      (wrap_data_addr   )    ,
            .data_wdata     (wrap_data_wdata  )   ,
            .data_rdata     (wrap_data_rdata  )   ,
            .data_addr_ok   (wrap_data_addr_ok) ,
            .data_data_ok   (wrap_data_data_ok) ,
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