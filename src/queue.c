#include "queue.h"
#include "thread.h"

#include <stdlib.h>
#include <stdio.h>
#include <assert.h>

struct node sentinel = {NULL, NULL};

#if Q_MEM_POOL

int queue__init(struct queue* queue, void* base)
{
	#if Q_LOOP
	queue->main_node.next = &queue->main_node;
	#else
	queue->main_node.next = &sentinel;
	#endif
	queue->main_node.value = base;
	queue->top = &queue->main_node;
	queue->end = &queue->main_node;
	queue->first_pool = malloc(sizeof(struct queue_pool) + Q_MEM_POOL_FS * sizeof(struct node));
	if (!queue->first_pool) {
		printf("queue__init erreur malloc\n");
		return -1;
	}
	queue->first_pool->next = NULL;
	queue->last_pool = queue->first_pool;
	queue->first_empty = NULL;
	queue->last_empty = &queue->first_pool->array[0];
	queue->free_space = Q_MEM_POOL_FS;
	queue->last_pool_size = Q_MEM_POOL_FS;
	return 0;
}

int queue__add(struct queue* queue, void* x)
{
	struct node* node;
	if ((node = queue->first_empty)) {
		queue->first_empty = queue->first_empty->next;
	} else if (queue->free_space) {
		node = queue->last_empty;
		queue->last_empty += 1;
		queue->free_space -= 1;
	} else {
	#if Q_MEM_POOL_G == EXPONENTIAL
		queue->last_pool_size *= Q_MEM_POOL_FS;
	#elif Q_MEM_POOL_G == LINEAR
		queue->last_pool_size += Q_MEM_POOL_FS;
	#elif Q_MEM_POOL_G == CONSTANT
			// Do nothing (queue->last_pool_size = Q_MEM_POOL_FS)
	#endif
		queue->last_pool->next = malloc(sizeof(struct queue_pool) + queue->last_pool_size * sizeof(struct node));
		if (!queue->last_pool->next) {
			while (queue->last_pool_size > 0) {
				queue->last_pool_size /= 2;
				queue->last_pool->next = malloc(sizeof(struct queue_pool) + queue->last_pool_size * sizeof(struct node));
				if (queue->last_pool->next)
					goto size_ok_queue;
			}
			printf("queue__add erreur malloc\n");
			return -1;
		}
	size_ok_queue:
		queue->last_pool = queue->last_pool->next;
		queue->last_pool->next = NULL;
		queue->free_space = queue->last_pool_size - 1;
		node = &queue->last_pool->array[0];
		queue->last_empty = &queue->last_pool->array[1];
	}

	node->value = x;
	#if Q_LOOP
	node->next = queue->top;
	#else
	node->next = &sentinel;
	#endif
	queue->end->next = node;
	queue->end = node;

	return 0;
}

/* Hypothèse : Il reste au moins un élément après pop (sinon on peut rendre l'état incohérent) */
void* queue__pop(struct queue* queue)
{
	struct node* top_node = queue->top;
	queue->top = top_node->next;

	#if Q_LOOP
	queue->end->next = top_node->next;
	#endif

	void* return_value = top_node->value;

	top_node->next = queue->first_empty;
	queue->first_empty = top_node;

	return return_value;
}

void queue__release(struct queue* queue)
{
	struct queue_pool* pool = queue->first_pool;
	struct queue_pool* temp;
	while (pool) {
		temp = pool;
		pool = pool->next;
		free(temp);
	}
}

#else

int queue__init(struct queue* queue, void* base)
{
	#if Q_LOOP
	queue->base.next = &queue->base;
	#else
	queue->base.next = &sentinel;
	#endif
	queue->base.value = base;
	queue->top = &queue->base;
	queue->end = &queue->base;

	return 0;
}

int queue__add(struct queue* queue, void* x)
{
	assert(queue->top != &sentinel);

	struct node* new_node = malloc(sizeof(struct node));
	if (!new_node)
		return -1;
	#if Q_LOOP
	new_node->next = queue->top;
	#else
	new_node->next = &sentinel;
	#endif
	new_node->value = x;

	queue->end->next = new_node;
	queue->end = new_node;

	return 0;
}

/* Hypothèse : Il reste au moins un élément après pop (sinon on peut rendre l'état incohérent) */
void* queue__pop(struct queue* queue)
{
	struct node* top_node = queue->top;
	queue->top = top_node->next;

	#if Q_LOOP
	if (top_node == queue->end)
		queue->top = &sentinel;
	queue->end->next = top_node->next;
	#endif

	void* return_value = top_node->value;

	if (top_node != &queue->base)
		free(top_node);

	// assert(queue->top != &sentinel);

	return return_value;
}

void queue__release(struct queue* queue)
{
	struct node* node = queue->top;
	struct node* temp;
	#if Q_LOOP
	if (node != &sentinel)
		do {
			temp = node;
			node = node->next;
			if (temp != &queue->base)
				free(temp);
		} while (node != queue->top);
	#else
	while (node != &sentinel) {
		temp = node;
		node = node->next;
		if (temp != &queue->base)
			free(temp);
	}
	#endif
}

#endif

void* queue__top(struct queue* queue)
{
	return queue->top->value;
}

int queue__roll(struct queue* queue)
{
#if Q_LOOP
	queue->end = queue->top;
	queue->top = queue->top->next;
#else
	queue->end->next = queue->top;

	queue->top = queue->top->next;

	queue->end = queue->end->next;
	queue->end->next = &sentinel;
#endif

	return 0;
}

int queue__has_one_element(struct queue* queue)
{
	return (queue->top == queue->end);
}

void queue__print(struct queue* queue)
{
	struct node* node = queue->top;
	int i = 0;
	printf("-----\n");
	do {
		printf("%d : %p\n", i, node->value);
		i += 1;
		node = node->next;
	} while (node != &sentinel && node != queue->top);

	if (node == &sentinel)
		printf("S####\n");
	else
		printf("T####\n");
}
