#include "queue.h"

struct node sentinel = {NULL, NULL};

void queue__init(struct queue* queue){
	queue->top=&sentinel;
	queue->end=&sentinel;
}

int queue__add(struct queue* queue, void* x)
{
	struct node* new_node = malloc(sizeof(struct node));
	if (!new_node)
		return -1;

	new_node->next = NULL;
	new_node->value = x;

	queue->end->next = new_node;

	return 0;
}

void* queue__top(struct queue* queue)
{
	return queue->top->value;
}

int queue__is_empty(struct queue* queue){
	return queue->top == queue->end;
}