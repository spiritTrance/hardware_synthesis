module bridge_1_2 (
    input           no_dcache,
    // cpu
    input           cpu_req     ,
    input           cpu_wr      ,
    input  [1 :0]   cpu_size    ,
    input  [31:0]   cpu_addr    ,
    input  [31:0]   cpu_wdata   ,
    output [31:0]   cpu_rdata   ,
    output          cpu_addr_ok ,
    output          cpu_data_ok ,
    // ram (cache optional)
    output          ram_req     ,
    output          ram_wr      ,
    output  [1 :0]  ram_size    ,
    output  [31:0]  ram_addr    ,
    output  [31:0]  ram_wdata   ,
    input   [31:0]  ram_rdata   ,
    input           ram_addr_ok ,
    input           ram_data_ok ,
    // confreg
    output          conf_req     ,
    output          conf_wr      ,
    output  [1 :0]  conf_size    ,
    output  [31:0]  conf_addr    ,
    output  [31:0]  conf_wdata   ,
    input   [31:0]  conf_rdata   ,
    input           conf_addr_ok ,
    input           conf_data_ok 
);
    assign cpu_rdata   = no_dcache ? conf_rdata   : ram_rdata  ;
    assign cpu_addr_ok = no_dcache ? conf_addr_ok : ram_addr_ok;
    assign cpu_data_ok = no_dcache ? conf_data_ok : ram_data_ok;

    assign ram_req   = no_dcache ? 0 : cpu_req  ;
    assign ram_wr    = no_dcache ? 0 : cpu_wr   ;
    assign ram_size  = no_dcache ? 0 : cpu_size ;
    assign ram_addr  = no_dcache ? 0 : cpu_addr ;
    assign ram_wdata = no_dcache ? 0 : cpu_wdata;

    assign conf_req   = no_dcache ? cpu_req   : 0;
    assign conf_wr    = no_dcache ? cpu_wr    : 0;
    assign conf_size  = no_dcache ? cpu_size  : 0;
    assign conf_addr  = no_dcache ? cpu_addr  : 0;
    assign conf_wdata = no_dcache ? cpu_wdata : 0;
endmodule