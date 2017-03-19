#ifndef _LINKEDLIST
#define _LINKEDLIST

#include "instructions.h"

typedef struct _listNode {
    void *data;
    struct _listNode *next;
} ListNode;

typedef ListNode *List;

void llAppend(List list, void *data);
void *llGet(List list, uint16_t index);
void llFree(List list);
List newLL();

#endif
