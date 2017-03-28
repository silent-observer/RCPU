#include "linkedlist.h"
#include <stdlib.h>
#include "error.h"

void llAppend(List list, void *data) {
    if (!list->data) {
        list->data = data;
        return;
    }
    else while (list->next)
        list = list->next;
    List new = (List) malloc(sizeof(ListNode));
    test(!new, "Cannot allocate storage for new linked list item\n");
    new->data = data;
    new->next = NULL;
    list->next = new;
}

List newLL() {
    List new = (List) malloc(sizeof(ListNode));
    test(!new, "Cannot allocate storage for new linked list item\n");
    new->data = NULL;
    new->next = NULL;
    return new;
}

uint16_t llLength(List list) {
    uint16_t len = list? 1: 0;
    while (list && list->next) {
        list = list->next;
        len++;
    }
    return len;
}

void *llGet(List list, uint16_t index) {
    while (list && list->next) {
        if (index == 0)
            return list->data;
        else {
            list = list->next;
            index--;
        }
    }
    test(1, "Linked list range violation\n");
}

void llFree(List list) {
    if (!list) return;
    while (list->next) {
        List listNext = list->next;
        free(list);
        list = listNext;
    }
    free(list);
}
