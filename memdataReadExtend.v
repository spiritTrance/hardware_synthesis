module memdataReadExtend(
    input   wire  [31: 0]   din,
    input   wire  [3: 0]    read_en,
    input   wire            sign,
    output  wire  [31: 0]   dout
);
    // read_en: 0001, 0010, 0100, 1000, 0011, 1100, 1111    high --- low
    wire [31: 0] word_data;
    wire [15: 0] half_data;
    wire [7: 0] byte_data;
    wire ren, rb, rh, rw;       // 判断是读字节，读半字还是字
    assign rb = (read_en == 4'b0001) | (read_en == 4'b0010) | (read_en == 4'b0100) | (read_en == 4'b1000); 
    assign rh = (read_en == 4'b0011) | (read_en == 4'b1100);
    assign rw = &read_en; 
    assign byte_data = (read_en == 4'b0001) ? din[7: 0]: 
                       (read_en == 4'b0010) ? din[15: 8]:
                       (read_en == 4'b0100) ? din[23: 16]:
                       (read_en == 4'b1000) ? din[31: 24]: 8'b0;
    assign half_data = (read_en == 4'b1100) ? din[31: 16]:
                       (read_en == 4'b0011) ? din[15: 0]: 16'b0;
    assign word_data = din;
    assign ren = | read_en;
    assign dout = ~ren ? 32'b0 :                                        // read_en为0
                    rb ? sign ? { {24{byte_data[7]}}, byte_data} :      // 读字节
                                {24'b0, byte_data} :
                    rh ? sign ? { {16{half_data[15]}}, half_data} :     // 读半字
                                { 16'b0, half_data} :
                    rw ? word_data : 32'b0;
endmodule