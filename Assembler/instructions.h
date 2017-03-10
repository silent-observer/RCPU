#ifndef _INSTRUCTIONS
#define _INSTRUCTIONS

#include <stdint.h>

struct AddrMode {
    int8_t sourceType;
    int16_t value;
};

struct AType {
    struct AddrMode s1;
    uint8_t opcode;
    uint8_t s2Type;
    struct AddrMode d;
};

struct JType {
    uint16_t address;
};

struct IType {
    uint8_t opcode;
    struct AddrMode sd;
    int8_t immediate;
}

struct SIType {
    struct AddrMode s;
    uint8_t opcode;
    struct AddrMode d;
    uint8_t immediate;
}

struct FType {
    uint8_t opcode;
    uint8_t flag;
    int8_t shift;
}

struct SPType {
    struct AddrMode sd;
    uint8_t opcode;
}

struct Instruction {
    int8_t type;
    union {
        struct AType aType;
        struct JType jType;
        struct IType iType;
        struct SIType siType;
        struct FType fType;
        struct SPType spType;
    };
};
// A type
#define ATYPE 0;
#define ADD 0
#define ADC 1
#define SUB 2
#define SBC 3
#define MUL 4
#define MLL 5
#define SGN 6
#define RAS 7
#define LSH 8
#define RSH 9
#define LRT 10
#define RRT 11
#define AND 12
#define OR 13
#define XOR 14
#define NOT 15
// J type
#define JTYPE 1;
// I type
#define ITYPE 2;
#define ADDI 0
#define ADCI 1
#define SUBI 2
#define SBCI 3
#define AND 4
#define OR 5
#define XOR 6
// SI type
#define SITYPE 3;
#define LSH 0
#define RSH 1
#define LRT 2
#define RRT 3
// F type
#define FTYPE 4;
#define JFC 0
#define JFS 1
#define FLC 2
#define FLS 3
// SP type
#define SPTYPE 5;
#define PUSH 0
#define POP 1
#define RET 3
// Addressing modes
#define MODE0 0;
#define MODEA 1;
#define MODEB 2;
#define MODEC 3;
#define MODEI 4;
#define MODEABS 5;
#define MODEAD 6;
#define MODEABSI 7;

#endif
