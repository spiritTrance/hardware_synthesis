// sram接口转sram-like接口
module sram_to_sram_like(
    input   wire                clk, areset,    // low active
    // sram
    input   wire                s_en,
    input   wire    [3: 0]      s_we,
    input   wire    [31:0]      s_addr,
    input   wire    [31:0]      s_wdata,
    output  wire    [31:0]      s_rdata,
    // sram - like
    output   reg                sl_req,
    output   reg                sl_wr,
    output   reg    [1 :0]      sl_size,
    output   wire   [31:0]      sl_addr,
    output   wire   [31:0]      sl_wdata,
    input    wire   [31:0]      sl_rdata,
    input    wire               sl_addr_ok,
    input    wire               sl_data_ok,
    // signal to cpu
    input    wire               pipelineStall,
    output   wire               stall
);
    localparam IDLE = 2'b00, ADDR = 2'b01, DATA = 2'b10, PIPEBUSY = 2'b11;
    reg     [3:0]               s_we_save;
    reg     [31:0]              s_addr_save, s_wdata_save;
    reg     [31:0]              s_rdata_save;
    wire                        addrException;
    reg     [1:0]               state;
    assign addrException = s_en ? (sl_size == 2'b10) ? |s_addr[1:0] :
                                  (sl_size == 2'b01) ? s_addr[0]    :
                                  1'b0 : 1'b0;
    assign s_rdata = s_rdata_save;
    assign sl_addr = s_addr_save;
    assign sl_wdata = s_wdata_save;
    always @(state) begin
        s_rdata_save = (~areset) ? 'b0 : 
                       (sl_data_ok) ? sl_rdata : s_rdata_save;          // 这个应该是Latch锁存器了，而不是flopper
    end
    assign stall =  ((~areset) | (s_en & ~sl_data_ok & ~addrException)) & (state != PIPEBUSY) ;         // 有en，且没有数据返回则停顿， 之前错误的做法是用IDLE，时序有点混乱
    // 控制状态，sl_req，sl_wr和sl_size
    always @(posedge clk) begin     // mealy型状态机
        if (~areset) begin
            state <= IDLE;
        end
        else begin
            case(state)
                IDLE: state <= (s_en & ~addrException) ? ADDR : IDLE;
                ADDR: state <= (sl_data_ok) ? IDLE :        // 可能 addr_ok 和 data_ok 同时来，因为有 cache 的缘故，那就先处理 data
                               (sl_addr_ok) ? DATA : ADDR;
                DATA: state <= (sl_data_ok) ? (pipelineStall) ? PIPEBUSY : IDLE : DATA;
                PIPEBUSY: state <= (pipelineStall) ? PIPEBUSY : IDLE;
                default: state <= IDLE;
            endcase
        end
    end
    always @(*) begin           // latch 锁存器
        if (~areset) begin
            s_we_save = 'b0;
            s_addr_save = 'b0;
            s_wdata_save = 'b0;
        end
        else begin
            case(state)
                IDLE: 
                    begin
                        s_we_save       = s_we;
                        s_addr_save     = s_addr;
                        s_wdata_save    = s_wdata;
                    end
                ADDR, DATA, PIPEBUSY:   
                    begin
                        s_we_save       = s_we_save;
                        s_addr_save     = s_addr_save;
                        s_wdata_save    = s_wdata_save;
                    end
                default:
                    begin
                        s_we_save       = 'b0;
                        s_addr_save     = 'b0;
                        s_wdata_save    = 'b0;
                    end
            endcase
        end
    end
    always @(state) begin       // 仍然是锁存器
        if (~areset) begin
            sl_wr   = 1'b0;
            sl_req  = 1'b0;
            sl_size = 2'b00;
        end
        else begin
            case(state)
                IDLE:
                    begin
                        sl_wr   = 1'b0;
                        sl_req  = 1'b0;
                        sl_size = 2'b00;
                    end
                ADDR:
                    begin
                        sl_wr   = |s_we_save;
                        sl_req  = 1'b1;
                        sl_size =  (s_we_save == 4'b1111) ? 2'b10 :
                                   (s_we_save == 4'b1100) ? 2'b01 :
                                   (s_we_save == 4'b0011) ? 2'b01 :
                                   (s_we_save == 4'b0001) ? 2'b00 :
                                   (s_we_save == 4'b0010) ? 2'b00 :
                                   (s_we_save == 4'b0100) ? 2'b00 :
                                   (s_we_save == 4'b1000) ? 2'b00 : 2'b00;
                    end
                DATA, PIPEBUSY:
                    begin
                        sl_wr   = sl_wr;
                        sl_req  = 1'b0;
                        sl_size = sl_size;
                    end
                default:
                    begin
                        sl_wr   = 1'b0;
                        sl_req  = 1'b0;
                        sl_size = 2'b00;
                    end
            endcase
        end
    end
endmodule

// 需要修改的地方：input是否要锁存；axi读写事务原理