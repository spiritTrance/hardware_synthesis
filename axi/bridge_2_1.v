module bridge_2_1 (
    input no_dcache,

    input         ram_req     ,
    input         ram_wr      ,
    input  [1 :0] ram_size    ,
    input  [31:0] ram_addr    ,
    input  [31:0] ram_wdata   ,
    output [31:0] ram_rdata   ,
    output        ram_addr_ok ,
    output        ram_data_ok ,

    input         conf_req     ,
    input         conf_wr      ,
    input  [1 :0] conf_size    ,
    input  [31:0] conf_addr    ,
    input  [31:0] conf_wdata   ,
    output [31:0] conf_rdata   ,
    output        conf_addr_ok ,
    output        conf_data_ok ,

    output        wrap_req     ,
    output        wrap_wr      ,
    output [1 :0] wrap_size    ,
    output [31:0] wrap_addr    ,
    output [31:0] wrap_wdata   ,
    input  [31:0] wrap_rdata   ,
    input         wrap_addr_ok ,
    input         wrap_data_ok
);

    assign ram_rdata   = no_dcache ? 0 : wrap_rdata  ;
    assign ram_addr_ok = no_dcache ? 0 : wrap_addr_ok;
    assign ram_data_ok = no_dcache ? 0 : wrap_data_ok;

    assign conf_rdata   = no_dcache ? wrap_rdata   : 0;
    assign conf_addr_ok = no_dcache ? wrap_addr_ok : 0;
    assign conf_data_ok = no_dcache ? wrap_data_ok : 0;

    assign wrap_req   = no_dcache ? conf_req   : ram_req  ;
    assign wrap_wr    = no_dcache ? conf_wr    : ram_wr   ;
    assign wrap_size  = no_dcache ? conf_size  : ram_size ;
    assign wrap_addr  = no_dcache ? conf_addr  : ram_addr ;
    assign wrap_wdata = no_dcache ? conf_wdata : ram_wdata;

endmodule