#ifndef __QUEUE_H__
#define __QUEUE_H__

#include <stddef.h>

struct node {
	void* value;
	struct node* next;
};

struct queue {
	struct node *top, end;
};

/* Fails if return value is -1 */

// Init and allocate memory
void queue__init(struct queue* queue);

// Add at the end and reallocate more memory if needed
int queue__add(struct queue* queue, void* x);

// Remove top element and returns it
void* queue__pop(struct queue* queue);

// Return top element
void* queue__top(struct queue* queue);

// Check if empty
int queue__is_empty(struct queue* queue);

#endif // __QUEUE_H__
