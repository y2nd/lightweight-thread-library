#include "queue.h"
#include "thread.h"

#include <stdlib.h>

// TODO : Queue avec iterateur ?
// TODO : Ajouter en 2e position ?
// TODO : Pool d'objets de même taille

#ifndef BETTER_QUEUE
struct node sentinel = {NULL, NULL};

void queue__init(struct queue* queue, void* base)
{
	queue->base.next = &sentinel;
	queue->base.value = base;
	queue->top = &queue->base;
	queue->end = &queue->base;
}

int queue__add(struct queue* queue, void* x)
{
	struct node* new_node = malloc(sizeof(struct node));
	if (!new_node)
		return -1;
	new_node->next = &sentinel;
	new_node->value = x;

	queue->end->next = new_node;
	queue->end = new_node;

	return 0;
}

void* queue__top(struct queue* queue)
{
	return queue->top->value;
}

void* queue__pop(struct queue* queue)
{
	struct node* top_node = queue->top;
	queue->top = top_node->next;

	void* return_value = top_node->value;

	if (top_node != &queue->base)
		free(top_node);

	// assert(queue->top != &sentinel);

	return return_value;
}

int queue__roll(struct queue* queue)
{
	// assert(queue->top != &sentinel);

	queue->end->next = queue->top;

	queue->top = queue->top->next;

	queue->end = queue->end->next;
	queue->end->next = &sentinel;

	return 0;
}

void queue__release(struct queue* queue)
{
	(void)queue;
}

int queue__has_one_element(struct queue* queue)
{
	return (queue->top == queue->end);
}

#else

	#define FIRST_SIZE 10

struct node sentinel = {NULL, NULL};

void queue__init(struct queue* queue, void* base)
{
	queue->pool = malloc(sizeof(struct node) * FIRST_SIZE);
	queue->pool[0].next = &sentinel;
	queue->pool[0].value = base;
	queue->top = &queue->pool[0];
	queue->end = &queue->pool[0];
	queue->empty = NULL;
	queue->last_empty = &queue->pool[1];
	queue->size = FIRST_SIZE;
	queue->free_space = FIRST_SIZE - 1;
}

int queue__add(struct queue* queue, void* x)
{
	if (queue->empty) {
		struct node* element = queue->empty;
		queue->empty = queue->empty->next;
		queue->end->next = element;
		queue->end = element;
		element->value = x;
		element->next = &sentinel;
		queue->free_space -= 1;
		return 0;
	}

	if (queue->free_space == 0) {
		queue->free_space = queue->size - 1;
		queue->pool = realloc(queue->pool, 2 * queue->size * sizeof(struct node));
		queue->last_empty = queue->pool + queue->size;
		queue->size *= 2;
	}

	struct node* element = queue->last_empty;
	queue->last_empty += 1;
	queue->end->next = element;
	queue->end = element;
	element->value = x;
	element->next = &sentinel;

	return 0;
}

void* queue__top(struct queue* queue)
{
	return queue->top->value;
}

void* queue__pop(struct queue* queue)
{
	struct node* top_node = queue->top;
	queue->top = top_node->next;

	void* return_value = top_node->value;
	top_node->value = NULL;

	top_node->next = queue->empty;
	queue->empty = top_node;

	// assert(queue->top != &sentinel);

	return return_value;
}

int queue__roll(struct queue* queue)
{
	// assert(queue->top != &sentinel);

	queue->end->next = queue->top;

	queue->top = queue->top->next;

	queue->end = queue->end->next;
	queue->end->next = &sentinel;

	return 0;
}

void queue__release(struct queue* queue)
{
	free(queue->pool);
}

int queue__has_one_element(struct queue* queue)
{
	return (queue->top == queue->end);
}

#endif
