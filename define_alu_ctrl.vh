/* 
 * this header defines the control signal of ALU from decoder
 * 这一个文件头定义了从译码器到ALU的控制信号宏
 */
 
// logic instruction
`define SIG_ALU_AND     5'b00_000
`define SIG_ALU_OR      5'b00_001
`define SIG_ALU_XOR     5'b00_010
`define SIG_ALU_NOR     5'b00_011
`define SIG_ALU_LUI     5'b00_100
// shift instruction
`define SIG_ALU_SLL     5'b00_101
`define SIG_ALU_SRL     5'b00_110
`define SIG_ALU_SRA     5'b00_111
`define SIG_ALU_SLLV    5'b01_000
`define SIG_ALU_SRLV    5'b01_001
`define SIG_ALU_SRAV    5'b01_010
// arithmetic instruction
`define SIG_ALU_ADD     5'b01_011
`define SIG_ALU_ADDU    5'b01_100
`define SIG_ALU_SUB     5'b01_101
`define SIG_ALU_SUBU    5'b01_110
`define SIG_ALU_SLT     5'b01_111
`define SIG_ALU_SLTU    5'b10_000
`define SIG_ALU_MULT    5'b10_001
`define SIG_ALU_MULTU   5'b10_010
`define SIG_ALU_DIV     5'b10_011
`define SIG_ALU_DIVU    5'b10_100
// datamove instruction
`define SIG_ALU_MFHI    5'b10_101
`define SIG_ALU_MFLO    5'b10_110
// branch and jump instruction
`define SIG_ALU_PC8     5'b10_111
// memory
`define SIG_ALU_MEM     5'b11_000
// fail
`define SIG_ALU_FAIL    5'b11_111