/* 
 * this header defines the macro of opcode and funct segment of instructions
 * 这一个文件头定义指令的opcode和funct字段的宏 
 */

// logic instruction (LOG)
// LOG - opcode
`define	OP_AND	6'b00_0000
`define	OP_OR	6'b00_0000
`define OP_XOR	6'b00_0000
`define OP_NOR	6'b00_0000
`define OP_ANDI	6'b00_1100
`define OP_XORI	6'b00_1110
`define OP_LUI	6'b00_1111
`define OP_ORI	6'b00_1101
// LOG - funct
`define FUNC_AND	6'b100100
`define FUNC_OR		6'b100101
`define FUNC_XOR	6'b100110
`define FUNC_NOR	6'b100111