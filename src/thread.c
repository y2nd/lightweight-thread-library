#include "thread.h"

#include "queue.h"
#include <stdio.h>
#include <stdlib.h>
#include <sys/ucontext.h>
#include <ucontext.h> /* ne compile pas avec -std=c89 ou -std=c99 */
#include <valgrind/valgrind.h>
#include <errno.h>
#include <stdint.h>

#ifdef __GNUC__
	#define INIT_QUEUE_IF_NEEDED 0
	#define CONSTRUCTOR			 __attribute__((constructor))
	#define DESTRUCTOR			 __attribute__((destructor))
#else
	#define INIT_QUEUE_IF_NEEDED init_main_thread_if_needed()
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
	void* return_value;
	int finished;
};

struct queue queue;
int is_initialized = 0;

struct thread main_thread;

static void DESTRUCTOR release_main_thread()
{
	queue__release(&queue);
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
	if (INIT_QUEUE_IF_NEEDED != 0)
		return -1;

	struct thread* thread = malloc(sizeof(struct thread));
	if (!thread) {
		error("thread_create malloc is null");
		return -1;
	}

	if (getcontext(&thread->uc) != 0) {
		error("thread_create getcontext");
		return -1;
	}
	thread->uc.uc_stack.ss_size = 64 * 1024;
	thread->uc.uc_stack.ss_sp = malloc(thread->uc.uc_stack.ss_size);
	if (!thread->uc.uc_stack.ss_sp) {
		error("thread_create malloc is null");
		return -1;
	}
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
	if (INIT_QUEUE_IF_NEEDED != 0)
		return -1;

	struct thread* thread_before = (struct thread*)queue__top(&queue);

	queue__roll(&queue);

	if (swapcontext(&(thread_before->uc), &((struct thread*)queue__top(&queue))->uc) != 0) {
		error("thread_yield swapcontext");
		return -1;
	}

	return 0;
}

int thread_join(thread_t thread, void** retval)
{
	struct thread* _thread = (struct thread*)thread;
	while (_thread->finished != 1)
		thread_yield();

	if (retval)
		*retval = _thread->return_value;
	free(_thread->uc.uc_stack.ss_sp);
	free(_thread);
	return 0;
}

void thread_exit(void* retval)
{
	struct thread* thread = (struct thread*)thread_self();

	if (thread == &main_thread) {
		exit((int)((intptr_t)retval));
	}

	if (queue__pop(&queue) != thread) {
		error("thread_exit queue__pop");
		exit(-1);
	}

	VALGRIND_STACK_DEREGISTER(thread->valgrind_stackid);

	thread->return_value = retval;
	thread->finished = 1;

	if (setcontext(&((struct thread*)queue__top(&queue))->uc) != 0) {
		error("thread_exit set_context");
	}
	exit(-1);
}
