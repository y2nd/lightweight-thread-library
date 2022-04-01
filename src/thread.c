#include "thread.h"

#include <stdio.h>
#include <stdlib.h>
#include <sys/ucontext.h>
#include <ucontext.h> /* ne compile pas avec -std=c89 ou -std=c99 */
#include <valgrind/valgrind.h>
#include <errno.h>

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

void launch(struct thread* thread, void* (*func)(void*), void* arg)
{
}

int thread_create(thread_t* newthread, void* (*func)(void*), void* funcarg)
{
	struct thread* thread = malloc(sizeof(struct thread));
	if (getcontext(&thread->uc) == -1) {
		error("thread_create getcontext");
		return -1;
	}
	thread->uc.uc_stack.ss_size = 64 * 1024;
	thread->uc.uc_stack.ss_sp = malloc(thread->uc.uc_stack.ss_size);
	thread->uc.uc_link = NULL; // WARN : (sizeof(ucontext_t));
	thread->valgrind_stackid = VALGRIND_STACK_REGISTER(thread->uc.uc_stack.ss_sp, thread->uc.uc_stack.ss_sp + thread->uc.uc_stack.ss_size);
	thread->finished = 0;

	makecontext(&thread->uc, (void (*)(void))launch, 3, thread, func, funcarg);

	*newthread = thread;
	return 0;
}
