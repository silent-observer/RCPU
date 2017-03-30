#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include "addresser.h"
#include "error.h"

#include "instrlist.h"

static Hashtable lt;
static DArray /*of InstructionNode */ instrs;

void initAddresser(Hashtable ht, DArray instrList)
{
    lt = ht;
    instrs = instrList;
}

void resolveReferences()
{
    InstructionNode *instrArray = (InstructionNode *) instrs.data;
    for (uint16_t i = 0; i < instrs.size; i++) {
        InstructionNode instr = instrArray[i];
        ArgumentNode *args = (ArgumentNode *) instr.args.data;
        for (uint16_t i = 0; i < instr.args.size; i++) {

            ArgumentNode *arg = &args[i];
            if (arg->label) {
                test(!htHas(lt, arg->label),
                     "Cannot find label with name '%s'", arg->label);
                if (instr.type < JCC_INDEX ||
                    instr.type > JVS_INDEX || instr.type == JMP_INDEX)
                    arg->value = htGet(lt, arg->label);
                else
                    arg->value = htGet(lt, arg->label) - instr.address - 1;
                free((void *) arg->label);
                arg->label = NULL;
            }
        }
    }
}
