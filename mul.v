module mul(
    input   wire                clk, rst, en,
    input   wire    [31:0]      a,
    input   wire    [31:0]      b,
    input   wire                sign,
    input   wire                interrupt,      // 主要是应对flush
    output                      data_ok,        // 计算好数据
    output  wire    [63:0]      result
);
    // mealy状态机设计：     idle -> busy -> idle
    // busy 到 idle 发出 data_ok 信号, 注意 en 信号和 data_ok 信号要一起判断下，
    // 状态机设计
    localparam IDLE = 2'b00, STAGE1 = 2'b01, STAGE2 = 2'b10;
    wire drive_en;
    reg [1: 0] state;
    assign drive_en = en & (state == IDLE);
    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
        end
        else begin
            case (state)
                IDLE:   state <= interrupt ? IDLE: drive_en ? STAGE1 : IDLE;
                STAGE1: state <= interrupt ? IDLE: STAGE2;
                STAGE2: state <= IDLE;
                default: state <= IDLE; 
            endcase
        end
    end
    // 参数定义
    wire sign_a = sign ? a[31] : 1'b0;
    wire sign_b = sign ? b[31] : 1'b0;
    wire [31:0] abs_a = sign_a ? ((~a) + 1) : a;
    wire [31:0] abs_b = sign_b ? ((~b) + 1) : b;
    wire [15:0] a1, a2, b1, b2;
    assign a1 = abs_a[31: 16];
    assign a2 = abs_a[15: 0 ];
    assign b1 = abs_b[31: 16];
    assign b2 = abs_b[15: 0 ];
    reg [31: 0] a1b1, a1b2, a2b1, a2b2;
    reg [63: 0] abs_result;
    // pipeline computing
    always @(posedge clk) begin
        if (rst) begin
            a1b1 <= 32'b0;
            a1b2 <= 32'b0;
            a2b1 <= 32'b0;
            a2b2 <= 32'b0;
        end
        else begin
            a1b1 <= a1 * b1;
            a1b2 <= a1 * b2;
            a2b1 <= a2 * b1;
            a2b2 <= a2 * b2;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            abs_result <= 64'b0;
        end
        else begin
            abs_result <= ( a1b1 << 32 ) + ( (a1b2 + a2b1) << 16 ) + a2b2;
        end
    end

    // 最终结果
    assign result = (sign_a ^ sign_b) ? (~abs_result + 1) : abs_result;
    assign data_ok = state == STAGE2;
    /* 波形图
    * en           _ - _ _ _
    * state        I I 1 2 I
    * data_ok      _ _ _ - _
    */
endmodule
