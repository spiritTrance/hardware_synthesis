/* 
 * this header defines the macro of opcode and funct segment of instructions
 * 这一个文件头定义指令的opcode和funct字段的宏 
 */

// logic instruction (LOG)
// LOG - opcode
`define OP_RTYPE     6'b00_0000
`define	OP_AND	        6'b00_0000
`define	OP_OR	        6'b00_0000
`define OP_XOR	        6'b00_0000
`define OP_NOR	        6'b00_0000
`define OP_ANDI	        6'b00_1100
`define OP_XORI	        6'b00_1110
`define OP_LUI	        6'b00_1111
`define OP_ORI	        6'b00_1101
// LOG - funct
`define FUNC_AND	6'b10_0100
`define FUNC_OR		6'b10_0101
`define FUNC_XOR	6'b10_0110
`define FUNC_NOR	6'b10_0111

// shift instruction (SHIFT)
// SHIFT - opcode
`define OP_SLL      6'b00_0000
`define OP_SRL      6'b00_0000
`define OP_SRA      6'b00_0000
`define OP_SLLV     6'b00_0000
`define OP_SRLV     6'b00_0000
`define OP_SRAV     6'b00_0000
// SHIFT - funct
`define FUNC_SLL    6'b00_0000  
`define FUNC_SRL    6'b00_0010  
`define FUNC_SRA    6'b00_0011
`define FUNC_SLLV   6'b00_0100 
`define FUNC_SRLV   6'b00_0110 
`define FUNC_SRAV   6'b00_0111 

// trap instruction (TRAP)
// TRAP - opcode
`define OP_BREAK    6'b00_0000
`define OP_SYSCALL  6'b00_0000
// TRAP - funct
`define FUNCT_BREAK    6'b00_1101
`define FUNCT_SYSCALL  6'b00_1100