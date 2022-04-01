#include "queue.h"

struct node sentinel = {NULL, NULL};

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

void* queue__pop(struct queue* queue)
{
	void* return_value;
}