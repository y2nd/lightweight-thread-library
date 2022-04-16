#ifndef __QUEUE_H__
#define __QUEUE_H__

#include <stddef.h>

#include "config.h"

struct node {
	void* value;
	struct node* next;
};

#ifndef Q_MEM_POOL
struct queue {
	struct node *top, *end;
	struct node base; // Node which won't be removed (for main thread)
};
#else
struct queue_pool {
	struct queue_pool* next;
	struct node array[];
};

struct queue {
	struct node *top, *end;
	struct node main_node;
	struct queue_pool *first_pool, *last_pool;
	struct node *first_empty, *last_empty;
	size_t free_space, last_pool_size;
};
#endif

/* Fails if return value is -1 */

// Init and allocate memory
int queue__init(struct queue* queue, void* base);

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

// Checks whether the queue has only one element
int queue__has_one_element(struct queue* queue);

#endif /* __QUEUE_H__ */
