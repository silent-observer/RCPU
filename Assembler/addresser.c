#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include "ast.h"
#include "linkedlist.h"
#include "hashtable.h"
#include "error.h"

static const char *jumpInstr[] = {
    "JCC", "JCS", "JEQ", "JFC", "JFS", "JGE", "JGT", "JLE", "JLT", "JNE",
    "JVC", "JVS"};
#define NUMINSTR sizeof(jumpInstr) / sizeof(jumpInstr[0])

static Hashtable lt;
static List/*of InstructionNode*/ instrs;

void initAddresser(Hashtable ht, List instrList)
{
    lt = ht;
    instrs = instrList;
}

static int voidstrcmp(const void *a, const void *b) { // Comparison of strings
    return strcmp(*(char**) a, *(char**) b);
}

void resolveReferences()
{
    foreach(i, instrs) {
        InstructionNode *instr = (InstructionNode*) i->data;
        foreach(j, instr->args) {
            ArgumentNode *arg = (ArgumentNode*) j->data;
            if (arg->label) {
                test(!htHas(lt, arg->label),
                    "Cannot find label with name '%s'", arg->label);
                char **match = (char**) bsearch(&instr->name, &jumpInstr[0],
                    NUMINSTR, sizeof(jumpInstr[0]), &voidstrcmp);
                if (!match) arg->value = htGet(lt, arg->label);
                else arg->value = htGet(lt, arg->label) - instr->address - 1;
                arg->label = NULL;
            }
        }
    }
}
