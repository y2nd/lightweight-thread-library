#include "thread.h"

#include "config.h"

#include "queue.h"
#include <stdio.h>
#include <stdlib.h>
#include <sys/ucontext.h>
#include <ucontext.h> /* ne compile pas avec -std=c89 ou -std=c99 */
#include <valgrind/valgrind.h>
#include <errno.h>
#include <stdint.h>

#if defined(__GNUC__) && USE_CTOR
	#define INIT_QUEUE_IF_NEEDED
	#define INIT_QUEUE_IF_NEEDED_RETURN
	#define CONSTRUCTOR __attribute__((constructor))
	#define DESTRUCTOR	__attribute__((destructor))
#else
	#define INIT_QUEUE_IF_NEEDED init_main_thread_if_needed()
	#define INIT_QUEUE_IF_NEEDED_RETURN        \
		if (init_main_thread_if_needed() != 0) \
			return -1;
	#define CONSTRUCTOR
	#define DESTRUCTOR
#endif

void error(const char* prefix)
{
	if (errno != 0)
		perror(prefix);
	else
		fprintf(stderr, "%s\n", prefix);
}

struct thread {
	ucontext_t uc;
	int valgrind_stackid;
	void* return_value; // Ou next
	int finished;
#if SCHED == FIFO
	struct thread* joiner;
#endif
	const char stack[64 * 1024];
};

#if T_MEM_POOL
struct thread_pool {
	struct thread_pool* next;
	struct thread array[];
};

struct threads {
	struct thread_pool *first_pool, *last_pool;
	struct thread *first_empty, *last_empty;
	size_t free_space, last_pool_size;
};

struct threads threads;
#endif

struct queue queue;
int is_initialized = 0;

struct thread main_thread;

static void DESTRUCTOR release_main_thread()
{
	queue__release(&queue);
#if T_MEM_POOL
	struct thread_pool* pool = threads.first_pool;
	struct thread_pool* temp;
	while (pool) {
		temp = pool;
		pool = pool->next;
		free(temp);
	}
#endif
}

static int CONSTRUCTOR init_main_thread_if_needed()
{
	if (!is_initialized) {
		if (getcontext(&main_thread.uc) != 0) {
			error("init_main_thread_if_needed getcontext");
			return -1;
		}
		main_thread.valgrind_stackid = -1;
		main_thread.finished = 0;

		queue__init(&queue, &main_thread);

		is_initialized = 1;

#if T_MEM_POOL
		threads.first_pool = malloc(sizeof(struct thread_pool) + T_MEM_POOL_FS * sizeof(struct thread));
		if (!threads.first_pool) {
			printf("init_main_thread_if_needed erreur malloc\n");
			return -1;
		}
		threads.first_pool->next = NULL;
		threads.last_pool = threads.first_pool;
		threads.first_empty = NULL;
		threads.last_empty = &threads.first_pool->array[0];
		threads.free_space = T_MEM_POOL_FS;
		threads.last_pool_size = T_MEM_POOL_FS;
#endif

#ifndef __GNUC__
		atexit(release_main_thread);
#endif
	}
	return 0;
}

thread_t thread_self(void)
{
	INIT_QUEUE_IF_NEEDED;
	return queue__top(&queue);
}

void launch(void* (*func)(void*), void* arg)
{
	thread_exit(func(arg));
}

int thread_create(thread_t* newthread, void* (*func)(void*), void* funcarg)
{
	INIT_QUEUE_IF_NEEDED_RETURN;

	// TODO : Ajouter le thread en 2 position, il va très rapidement servir

#if T_MEM_POOL
	struct thread* thread;
	if ((thread = threads.first_empty)) {
		threads.first_empty = threads.first_empty->return_value; // return_value = next ici
	} else if (threads.free_space) {
		thread = threads.last_empty;
		threads.last_empty += 1;
		threads.free_space -= 1;
	} else {
	#if T_MEM_POOL_G == EXPONENTIAL
		threads.last_pool_size *= T_MEM_POOL_FS;
	#elif T_MEM_POOL_G == LINEAR
		threads.last_pool_size += T_MEM_POOL_FS;
	#elif T_MEM_POOL_G == CONSTANT
			// Do nothing (threads.last_pool_size = T_MEM_POOL_FS)
	#endif
		threads.last_pool->next = malloc(sizeof(struct thread_pool) + threads.last_pool_size * sizeof(struct thread));
		if (!threads.last_pool->next) {
			printf("thread_create erreur malloc\n");
			return -1;
		}
		threads.last_pool = threads.last_pool->next;
		threads.last_pool->next = NULL;
		threads.free_space = threads.last_pool_size - 1;
		thread = &threads.last_pool->array[0];
		threads.last_empty = &threads.last_pool->array[1];
	}
#else
	struct thread* thread = malloc(sizeof(struct thread));
#endif
	if (!thread) {
		error("thread_create malloc is null");
		return -1;
	}

	if (getcontext(&thread->uc) != 0) {
		error("thread_create getcontext");
		return -1;
	}
	thread->uc.uc_stack.ss_size = 64 * 1024;
	thread->uc.uc_stack.ss_sp = (void*)thread->stack;
	if (!thread->uc.uc_stack.ss_sp) {
		error("thread_create malloc is null");
		return -1;
	}
#if SCHED == FIFO
	thread->joiner = NULL;
#endif
	thread->uc.uc_link = NULL; // WARN : (sizeof(ucontext_t));
	thread->valgrind_stackid = VALGRIND_STACK_REGISTER(thread->uc.uc_stack.ss_sp, thread->uc.uc_stack.ss_sp + thread->uc.uc_stack.ss_size);
	thread->finished = 0;

	makecontext(&thread->uc, (void (*)(void))launch, 2, func, funcarg);

	queue__add(&queue, thread);

	*newthread = thread;
	return 0;
}

int thread_yield(void)
{
	INIT_QUEUE_IF_NEEDED_RETURN;

	struct thread* thread_before = (struct thread*)queue__top(&queue);

	queue__roll(&queue);

	// TODO : Possibilité de s'économiser le swapcontext (si le thread attend sur un qui a pas fini, on swap pas)

	if (swapcontext(&(thread_before->uc), &((struct thread*)queue__top(&queue))->uc) != 0) {
		error("thread_yield swapcontext");
		return -1;
	}

	return 0;
}

int thread_join(thread_t thread, void** retval)
{
	struct thread* _thread = (struct thread*)thread;
#if SCHED == BASIC
	while (_thread->finished != 1)
		thread_yield();
#elif SCHED == FIFO
	if (_thread->finished != 1) {
		_thread->joiner = queue__pop(&queue); // Le joiner s'enlève de la file
		if (swapcontext(&(_thread->joiner->uc), &((struct thread*)queue__top(&queue))->uc) != 0) {
			error("thread_yield swapcontext");
			return -1;
		}
	}
#endif

	if (retval)
		*retval = _thread->return_value;
	if (_thread != &main_thread) {
#if T_MEM_POOL
		_thread->return_value = threads.first_empty; // return_value = next ici
		threads.first_empty = _thread;
#else
		free(_thread);
#endif
	}
	return 0;
}

void thread_exit(void* retval)
{
	struct thread* thread = queue__top(&queue);

	int last_element;

#if SCHED == BASIC
	last_element = queue__has_one_element(&queue);
#elif SCHED == FIFO
	if (thread->joiner) {
		last_element = 0;
		queue__add(&queue, thread->joiner); // On ajoute le joiner à la fin
	} else
		last_element = queue__has_one_element(&queue);
#endif

	if (last_element) {
		if (thread == &main_thread) {
			exit((int)(intptr_t)retval);
		} else {
			VALGRIND_STACK_DEREGISTER(thread->valgrind_stackid);
			main_thread.return_value = retval;
			if (setcontext(&main_thread.uc) != 0) {
				error("thread_exit set_context");
			}
			exit(-1);
		}
	} else {
		queue__pop(&queue);
		if (thread == &main_thread) {
			main_thread.return_value = retval;
			main_thread.finished = 1;
			if (swapcontext(&main_thread.uc, &((struct thread*)queue__top(&queue))->uc) != 0) {
				error("thread_exit set_context");
			}
			// Pas besoin de laisser la pool de thread avec un bon first_empty
#if !T_MEM_POOL
			free(queue__pop(&queue));
#endif
			exit((int)(intptr_t)main_thread.return_value);
		} else {
			VALGRIND_STACK_DEREGISTER(thread->valgrind_stackid);
			thread->return_value = retval;
			thread->finished = 1;
			if (setcontext(&((struct thread*)queue__top(&queue))->uc) != 0) {
				error("thread_exit set_context");
			}
			exit(-1);
		}
	}
}
