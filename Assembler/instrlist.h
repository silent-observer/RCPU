#ifndef _INSTRLIST
#define _INSTRLIST

#ifdef DEFINE_INSTR_LIST

static const char *instrList[] = {
    "ADC", "ADCI", "ADD", "ADDI", "AND", "ANDI",
    "FLC", "FLS",
    "JCC", "JCS", "JEQ", "JFC", "JFS", "JGE", "JLT", "JMP", "JNE",
    "JVC", "JVS",
    "LRT", "LRTI", "LSH", "LSHI",
    "MLL", "MOV", "MUL",
    "NOT",
    "OR", "ORI",
    "POP", "PUSH",
    "RAS", "RET", "RRT", "RRTI", "RSH", "RSHI",
    "SBC", "SBCI", "SGN", "SUB", "SUBI",
    "XOR", "XORI"
};

#endif

#define NUMINSTR sizeof(instrList) / sizeof(instrList[0])

#define ADC_INDEX 0
#define ADCI_INDEX 1
#define ADD_INDEX 2
#define ADDI_INDEX 3
#define AND_INDEX 4
#define ANDI_INDEX 5

#define FLC_INDEX 6
#define FLS_INDEX 7

#define JCC_INDEX 8
#define JCS_INDEX 9
#define JEQ_INDEX 10
#define JFC_INDEX 11
#define JFS_INDEX 12
#define JGE_INDEX 13
#define JLT_INDEX 14
#define JMP_INDEX 15
#define JNE_INDEX 16
#define JVC_INDEX 17
#define JVS_INDEX 18

#define LRT_INDEX 19
#define LRTI_INDEX 20
#define LSH_INDEX 21
#define LSHI_INDEX 22

#define MLL_INDEX 23
#define MOV_INDEX 24
#define MUL_INDEX 25

#define NOT_INDEX 26

#define OR_INDEX 27
#define ORI_INDEX 28

#define POP_INDEX 29
#define PUSH_INDEX 30

#define RAS_INDEX 31
#define RET_INDEX 32
#define RRT_INDEX 33
#define RRTI_INDEX 34
#define RSH_INDEX 35
#define RSHI_INDEX 36

#define SBC_INDEX 37
#define SBCI_INDEX 38
#define SGN_INDEX 39
#define SUB_INDEX 40
#define SUBI_INDEX 41

#define XOR_INDEX 42
#define XORI_INDEX 43

#endif
