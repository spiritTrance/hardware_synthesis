/* 
 * this header defines the macro of opcode and funct segment of instructions
 * 这一个文件头定义指令的opcode和funct字段的宏 
 */
`define OP_RTYPE     6'b00_0000

// logic instruction (LOG)
    // LOG - opcode
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

// data move instruction (MOV)
    // MOV - opcode
    `define OP_MFHI     6'b00_0000
    `define OP_MFLO     6'b00_0000
    `define OP_MTHI     6'b00_0000
    `define OP_MTLO     6'b00_0000
    // MOV - funct
    `define FUNC_MFHI     6'b010000
    `define FUNC_MFLO     6'b010010
    `define FUNC_MTHI     6'b010001
    `define FUNC_MTLO     6'b010011

// arithmetic instruction (ARITH)
    // ARITH - opcode
    `define OP_ADD      6'b000000
    `define OP_ADDU     6'b000000
    `define OP_SUB      6'b000000
    `define OP_SUBU     6'b000000
    `define OP_SLT      6'b000000
    `define OP_SLTU     6'b000000
    `define OP_MULT     6'b000000
    `define OP_MULTU    6'b000000
    `define OP_DIV      6'b000000
    `define OP_DIVU     6'b000000
    `define OP_ADDI     6'b001000
    `define OP_ADDIU    6'b001001
    `define OP_SLTI     6'b001010
    `define OP_SLTIU    6'b001011
    // ARITH - funct
    `define FUNC_ADD      6'b100000
    `define FUNC_ADDU     6'b100001
    `define FUNC_SUB      6'b100010
    `define FUNC_SUBU     6'b100011
    `define FUNC_SLT      6'b101010
    `define FUNC_SLTU     6'b101011
    `define FUNC_MULT     6'b011000
    `define FUNC_MULTU    6'b011001
    `define FUNC_DIV      6'b011010
    `define FUNC_DIVU     6'b011011

// branch and jump instruction (BJ)
    // BJ - opcode
    `define OP_JR       6'b000000
    `define OP_JALR     6'b000000
    `define OP_J        6'b000010
    `define OP_JAL      6'b000011
    `define OP_BEQ      6'b000100
    `define OP_BGTZ     6'b000111
    `define OP_BLEZ     6'b000110
    `define OP_BNE      6'b000101
    `define OP_BLTZ     6'b000001
    `define OP_BLTZAL   6'b000001
    `define OP_BGEZ     6'b000001
    `define OP_BGEZAL   6'b000001
    // BJ - funct
    `define FUNC_JR     6'b001000
    `define FUNC_JALR   6'b001001

// memory accessing instruction (MEM)
    // MEM - opcode
    `define OP_LB       6'b100000
    `define OP_LBU      6'b100100
    `define OP_LH       6'b100001
    `define OP_LHU      6'b100101
    `define OP_LW       6'b100011
    `define OP_SB       6'b101000
    `define OP_SH       6'b101001
    `define OP_SW       6'b101011
    
// trap instruction (TRAP)
    // TRAP - opcode
    `define OP_BREAK    6'b00_0000
    `define OP_SYSCALL  6'b00_0000
    // TRAP - funct
    `define FUNCT_BREAK    6'b00_1101
    `define FUNCT_SYSCALL  6'b00_1100

// privilege instruction (PRIV)
    // PRIV - opcode
    `define OP_PRIVILEGE    6'b010000