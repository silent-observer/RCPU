#ifndef _INSTRUCTIONS
#define _INSTRUCTIONS

#include <stdint.h>

typedef struct {
    int8_t sourceType;
    int16_t value;
} AddrMode;

typedef union {
    int16_t immediate;
    char *label;
} LabelUse;

typedef struct {
    AddrMode s1;
    uint8_t opcode;
    uint8_t s2Type;
    AddrMode d;
} AType;

typedef struct {
    LabelUse address;
} JType;

typedef struct {
    uint8_t opcode;
    AddrMode sd;
    LabelUse immediate;
} IType;

typedef struct {
    AddrMode s;
    uint8_t opcode;
    AddrMode d;
    LabelUse immediate;
} SIType;

typedef struct {
    uint8_t opcode;
    uint8_t flag;
    LabelUse shift;
} FType;

typedef struct {
    AddrMode sd;
    uint8_t opcode;
} SPType;

typedef struct {
    int8_t type;
    union {
        AType aType;
        JType jType;
        IType iType;
        SIType siType;
        FType fType;
        SPType spType;
    };
} Instruction;


// A type
#define ATYPE 0
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
#define JTYPE 1
// I type
#define ITYPE 2
#define ADDI 0
#define ADCI 1
#define SUBI 2
#define SBCI 3
#define ANDI 4
#define ORI 5
#define XORI 6
// SI type
#define SITYPE 3
#define LSHI 0
#define RSHI 1
#define LRTI 2
#define RRTI 3
// F type
#define FTYPE 4
#define JFC 0
#define JFS 1
#define FLC 2
#define FLS 3
// SP type
#define SPTYPE 5
#define PUSH 0
#define POP 1
#define RET 3
// ERROR
#define IERROR 6
// Addressing modes
#define MODE0 0
#define MODEA 1
#define MODEB 2
#define MODEC 3
#define MODEI 4
#define MODEABS 5
#define MODEAD 6
#define MODEABSI 7

#endif
