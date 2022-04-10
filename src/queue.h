#ifndef __QUEUE_H__
#define __QUEUE_H__

#include <stddef.h>

struct node {
	void* value;
	struct node* next;
};

#ifndef BETTER_QUEUE
struct queue {
	struct node *top, *end;
	struct node base; // Node which won't be removed (for main thread)
};
#else
struct queue {
	struct node *top, *end;
	struct node* pool;
	struct node *empty, *last_empty;
	size_t size, free_space;
};
#endif

/* Fails if return value is -1 */

// Init and allocate memory
void queue__init(struct queue* queue, void* base);

// Add at the end and reallocate more memory if needed
int queue__add(struct queue* queue, void* x);

// Remove top element and returns it
void* queue__pop(struct queue* queue);

// Return top element
void* queue__top(struct queue* queue);

// Add and pop
int queue__roll(struct queue* queue);

// Releases queue resources (if needed)
void queue__release(struct queue* queue);

#endif // __QUEUE_H__
