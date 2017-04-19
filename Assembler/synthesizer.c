#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include "synthesizer.h"
#include "error.h"

#include "instrlist.h"

#define MAX 1000

#define toBinary(temp, value, size)             \
    char temp[size];                            \
    {                                           \
        char *_p = &temp[size-1];               \
        uint16_t _v = value;                    \
        for (uint8_t _i = 0; _i < size; _i++) { \
            if (_v & 1)                         \
                *_p-- = '1';                    \
            else                                \
                *_p-- = '0';                    \
            _v >>= 1;                           \
        }                                       \
    }


static DArray /*of InstructionNode */ instrs;

void initSynth(DArray instr)
{
    instrs = instr;
}

static const char *fullArgumentBin[] = {
    "000_", "001_", "010_", "011_",
    "100_", "101_", "110_", "111_"
};

static const char *partArgumentBin[] = {
    "00_", "01_", "10_", "11_"
};

static void synthArgument(DArray * str, const ArgumentNode arg)
{
    if (arg.sourceType == MODEI ||
        arg.sourceType == MODEABS || arg.sourceType == MODEABSI) {
        toBinary(temp, arg.value >> 16, 16);
        daAppendN(str, " ", 1);
        daAppendN(str, temp, 16);
    }
    if (arg.sourceType == MODEABS || arg.sourceType == MODEABSI) {
        toBinary(temp, arg.value & 0xFFFF, 16);
        daAppendN(str, " ", 1);
        daAppendN(str, temp, 16);
    }
}

static DArray synthAType(InstructionNode instr)
{
    test(instr.args.size != 3, "Invalid argument count %d "
         "while expected 3: %s\n", instr.args.size, instrToString(instr));
    DArray str = newDArray(30, sizeof(char));
    daAppendN(&str, "0000_", 5);
    ArgumentNode *args = (ArgumentNode *) instr.args.data;
    daAppendN(&str, fullArgumentBin[args[0].sourceType], 4);
    char opcode[6];
    switch (instr.type) {
    case ADD_INDEX:
        strcpy(opcode, "0000_");
        break;
    case ADC_INDEX:
        strcpy(opcode, "0001_");
        break;
    case SUB_INDEX:
        strcpy(opcode, "0010_");
        break;
    case SBC_INDEX:
        strcpy(opcode, "0011_");
        break;
    case MUL_INDEX:
        strcpy(opcode, "0100_");
        break;
    case MLL_INDEX:
        strcpy(opcode, "0101_");
        break;
    case SGN_INDEX:
        strcpy(opcode, "0110_");
        break;
    case RAS_INDEX:
        strcpy(opcode, "0111_");
        break;
    case LSH_INDEX:
        strcpy(opcode, "1000_");
        break;
    case RSH_INDEX:
        strcpy(opcode, "1001_");
        break;
    case LRT_INDEX:
        strcpy(opcode, "1010_");
        break;
    case RRT_INDEX:
        strcpy(opcode, "1011_");
        break;
    case AND_INDEX:
        strcpy(opcode, "1100_");
        break;
    case OR_INDEX:
        strcpy(opcode, "1101_");
        break;
    case XOR_INDEX:
        strcpy(opcode, "1110_");
        break;
    case NOT_INDEX:
        strcpy(opcode, "1111_");
        break;
    default:
        test(1, "Unknown A-Type instruction : %d\n", instr.type);
    }
    daAppendN(&str, opcode, 5);
    test(args[1].sourceType >= 4, "Cannot use non-register "
         "for second argument for A-Type instructions: %s\n",
         instrToString(instr));
    daAppendN(&str, partArgumentBin[args[1].sourceType], 3);
    daAppendN(&str, fullArgumentBin[args[2].sourceType], 3);
    synthArgument(&str, args[0]);
    synthArgument(&str, args[2]);
    daAppendN(&str, "\n", 1);
    free(args);
    return str;
}

static DArray synthJType(InstructionNode instr)
{
    test(instr.args.size != 1, "Invalid argument count %d "
         "while expected 1: %s\n", instr.args.size, instrToString(instr));
    DArray str = newDArray(20, sizeof(char));
    daAppendN(&str, "1_", 2);
    ArgumentNode *args = (ArgumentNode *) instr.args.data;
    toBinary(temp, args[0].value, 16);
    daAppendN(&str, temp + 1, 15);
    daAppendN(&str, "\n", 1);
    free(args);
    return str;
}

static DArray synthIType(InstructionNode instr)
{
    test(instr.args.size != 2, "Invalid argument count %d "
         "while expected 2: %s\n", instr.args.size, instrToString(instr));
    DArray str = newDArray(30, sizeof(char));
    daAppendN(&str, "01_", 3);
    char opcode[4];
    switch (instr.type) {
    case ADDI_INDEX:
    case ANDI_INDEX:
        strcpy(opcode, "00_");
        break;
    case ADCI_INDEX:
    case ORI_INDEX:
        strcpy(opcode, "01_");
        break;
    case SUBI_INDEX:
    case XORI_INDEX:
        strcpy(opcode, "10_");
        break;
    case SBCI_INDEX:
        strcpy(opcode, "11_");
        break;
    default:
        test(1, "Unknown I-Type instruction : %d", instr.type);
    }
    daAppendN(&str, opcode, 3);
    ArgumentNode *args = (ArgumentNode *) instr.args.data;
    daAppendN(&str, fullArgumentBin[args[0].sourceType], 4);
    switch (instr.type) {
    case ADDI_INDEX:
    case ADCI_INDEX:
    case SUBI_INDEX:
    case SBCI_INDEX:
        strcpy(opcode, "0_");
        break;
    case ANDI_INDEX:
    case ORI_INDEX:
    case XORI_INDEX:
        strcpy(opcode, "1_");
        break;
    default:
        test(1, "Unknown I-Type instruction : %d\n", instr.type);
    }
    test(args[1].sourceType != MODEI, "Cannot use non-immediate "
         "for second argument for I-Type instructions: %s\n",
         instrToString(instr));
    daAppendN(&str, opcode, 2);
    toBinary(temp, args[1].value & 0xFF, 8);
    daAppendN(&str, temp, 8);
    synthArgument(&str, args[0]);
    daAppendN(&str, "\n", 1);
    free(args);
    return str;
}

static DArray synthSIType(InstructionNode instr)
{
    test(instr.args.size != 3, "Invalid argument count %d "
         "while expected 3: %s\n", instr.args.size, instrToString(instr));
    DArray str = newDArray(30, sizeof(char));
    daAppendN(&str, "0001_", 5);
    ArgumentNode *args = (ArgumentNode *) instr.args.data;
    daAppendN(&str, fullArgumentBin[args[0].sourceType], 4);
    char opcode[4];
    switch (instr.type) {
    case LSHI_INDEX:
        strcpy(opcode, "00_");
        break;
    case RSHI_INDEX:
        strcpy(opcode, "01_");
        break;
    case LRTI_INDEX:
        strcpy(opcode, "10_");
        break;
    case RRTI_INDEX:
        strcpy(opcode, "11_");
        break;
    default:
        test(1, "Unknown SI-Type instruction : %d\n", instr.type);
    }
    daAppendN(&str, opcode, 3);
    daAppendN(&str, fullArgumentBin[args[2].sourceType], 4);
    test(args[1].sourceType != MODEI, "Cannot use non-immediate "
         "for second argument for I-Type instructions: %s\n",
         instrToString(instr));
    toBinary(temp, args[1].value & 0x0F, 4);
    daAppendN(&str, temp, 4);
    synthArgument(&str, args[0]);
    synthArgument(&str, args[2]);
    daAppendN(&str, "\n", 1);
    free(args);
    return str;
}

static DArray synthFType(InstructionNode instr)
{
    if (instr.type == JFC_INDEX || instr.type == JFS_INDEX)
        test(instr.args.size != 2, "Invalid argument count %d "
             "while expected 2: %s\n", instr.args.size,
             instrToString(instr));
    else
        test(instr.args.size != 1, "Invalid argument count %d "
             "while expected 1: %s\n", instr.args.size,
             instrToString(instr));
    DArray str = newDArray(30, sizeof(char));
    daAppendN(&str, "0010_", 5);
    char opcode[4];
    switch (instr.type) {
    case JFC_INDEX:
        strcpy(opcode, "00_");
        break;
    case JFS_INDEX:
        strcpy(opcode, "01_");
        break;
    case FLC_INDEX:
        strcpy(opcode, "10_");
        break;
    case FLS_INDEX:
        strcpy(opcode, "11_");
        break;
    default:
        test(1, "Unknown F-Type instruction : %d\n", instr.type);
    }
    daAppendN(&str, opcode, 3);
    ArgumentNode *args = (ArgumentNode *) instr.args.data;
    uint8_t flag = (instr.type == JFC_INDEX || instr.type == JFS_INDEX) ?
        args[1].value : args[0].value;
    switch (flag) {
    case 0:
        strcpy(opcode, "00_");
        break;
    case 1:
        strcpy(opcode, "01_");
        break;
    case 2:
        strcpy(opcode, "10_");
        break;
    case 3:
        strcpy(opcode, "11_");
        break;
    default:
        test(1, "Unknown F-Type instruction flag: %d\n", flag);
    }
    daAppendN(&str, opcode, 3);
    if (instr.type == JFC_INDEX || instr.type == JFS_INDEX) {
        toBinary(temp, args[0].value & 0xFF, 8);
        daAppendN(&str, temp, 8);
    } else
        daAppendN(&str, "00000000", 8);
    daAppendN(&str, "\n", 1);
    free(args);
    return str;
}

static DArray synthSPType(InstructionNode instr)
{
    if (instr.type != SVPC_INDEX)
        test(instr.args.size != 1, "Invalid argument count %d "
            "while expected 1: %s\n", instr.args.size, instrToString(instr));
    else
        test(instr.args.size != 2, "Invalid argument count %d "
            "while expected 2: %s\n", instr.args.size, instrToString(instr));
    DArray str = newDArray(30, sizeof(char));
    daAppendN(&str, "0011_", 5);
    ArgumentNode *args = (ArgumentNode *) instr.args.data;
    switch (instr.type) {
    case PUSH_INDEX:
        if (args[0].sourceType == MODEABS && args[0].value < 128) {
            daAppendN(&str, "000_00_", 7);
            toBinary(temp, args[0].value & 0x7F, 7);
            daAppendN(&str, temp, 7);
        } else {
            daAppendN(&str, fullArgumentBin[args[0].sourceType], 4);
            daAppendN(&str, "00_0000000", 10);
            synthArgument(&str, args[0]);
        }
        break;
    case POP_INDEX:
        if (args[0].sourceType == MODEABS && args[0].value < 128) {
            daAppendN(&str, "000_01_", 7);
            toBinary(temp, args[0].value & 0x7F, 7);
            daAppendN(&str, temp, 7);
        } else {
            daAppendN(&str, fullArgumentBin[args[0].sourceType], 4);
            daAppendN(&str, "01_0000000", 10);
            synthArgument(&str, args[0]);
        }
        break;
    case SVPC_INDEX: {
        daAppendN(&str, fullArgumentBin[args[0].sourceType], 4);
        daAppendN(&str, "10_", 3);
        toBinary(temp, args[1].value & 0x7F, 7);
        daAppendN(&str, temp, 7);
        synthArgument(&str, args[0]);
        break;
    }
    case RET_INDEX: {
        daAppendN(&str, "000_11_", 7);
        toBinary(temp, args[0].value & 0x7F, 7);
        daAppendN(&str, temp, 7);
        break;
    }
    default:
        test(1, "Unknown SP-Type instruction : %d\n", instr.type);
    }
    daAppendN(&str, "\n", 1);
    free(args);
    return str;
}

static DArray synthInstr(InstructionNode instr)
{
    switch (instr.type) {
    case ADD_INDEX:
    case ADC_INDEX:
    case SUB_INDEX:
    case SBC_INDEX:
    case MUL_INDEX:
    case MLL_INDEX:
    case SGN_INDEX:
    case RAS_INDEX:
    case LSH_INDEX:
    case RSH_INDEX:
    case LRT_INDEX:
    case RRT_INDEX:
    case AND_INDEX:
    case OR_INDEX:
    case XOR_INDEX:
    case NOT_INDEX:
        return synthAType(instr);
    case JMP_INDEX:
        return synthJType(instr);
    case ADDI_INDEX:
    case ADCI_INDEX:
    case SUBI_INDEX:
    case SBCI_INDEX:
    case ANDI_INDEX:
    case ORI_INDEX:
    case XORI_INDEX:
        return synthIType(instr);
    case LSHI_INDEX:
    case RSHI_INDEX:
    case LRTI_INDEX:
    case RRTI_INDEX:
        return synthSIType(instr);
    case JFC_INDEX:
    case JFS_INDEX:
    case FLC_INDEX:
    case FLS_INDEX:
        return synthFType(instr);
    case PUSH_INDEX:
    case POP_INDEX:
    case SVPC_INDEX:
    case RET_INDEX:
        return synthSPType(instr);
    default:
        test(1, "Unknown instruction type: %d\n", instr.type);
    }
}

char *synthesize()
{
    DArray result = newDArray(1000, sizeof(char));
    InstructionNode *instrArray = instrs.data;
    for (uint16_t i = 0; i < instrs.size; i++) {
        DArray parsedInstr = synthInstr(instrArray[i]);
        daAppendArr(&result, &parsedInstr);
        free(parsedInstr.data);
    }
    daAppend(&result, "");      // To end a string
    return (char *) result.data;
}
