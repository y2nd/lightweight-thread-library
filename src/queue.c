#include "queue.h"

#include <stdlib.h>

struct node sentinel = {NULL, NULL};

void queue__init(struct queue* queue)
{
	queue->top = &sentinel;
	queue->end = &sentinel;
}

int queue__add(struct queue* queue, void* x)
{
	struct node* new_node = malloc(sizeof(struct node));
	if (!new_node)
		return -1;
	new_node->next = &sentinel;
	new_node->value = x;

	if (queue->top == &sentinel) {
		queue->top = new_node;
		queue->end = new_node;
	} else {
		queue->end->next = new_node;
		queue->end = new_node;
	}

	return 0;
}

void* queue__top(struct queue* queue)
{
	return queue->top->value;
}

int queue__is_empty(struct queue* queue)
{
	return queue->top == &sentinel || queue->end == &sentinel;
}

void* queue__pop(struct queue* queue)
{
	struct node* top_node = queue->top;
	queue->top = top_node->next;

	void* return_value = top_node->value;

	free(top_node);

	if (queue->top == &sentinel)
		queue->end = &sentinel;

	return return_value;
}
