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

struct queue* queue;
int isinit = 0;

thread_t thread_self(void) 
{
  if (!isinit) {
    queue__init(queue);
    isinit = 1;
  }
  return queue__top(queue);
}

void launch(struct thread* thread, void* (*func)(void*), void* arg)
{
  void* return_value = func(arg);
  error("error creating thread");
  exit(1);
  thread->return_value = return_value;
}

int thread_create(thread_t* newthread, void* (*func)(void*), void* funcarg)
{
    if (!isinit) {
    queue__init(queue);
    queue__add(queue, NULL); //!!!!
    isinit = 1;
  }
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

	makecontext(&thread->uc, (void (*)(void))#include "thread.h"

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

struct queue* queue;
int isinit = 0;

thread_t thread_self(void) 
{
  if (!isinit) {
    queue__init(queue);
    isinit = 1;
  }
  return queue__top(queue);
}

void init_main_thread(thread_t* thread) 
{
  getcontext(&thread->uc);
  thread->uc.uc_stack.ss_size = 64 * 1024;
	thread->uc.uc_stack.ss_sp = malloc(thread->uc.uc_stack.ss_size);
	thread->uc.uc_link = NULL; // WARN : (sizeof(ucontext_t));
	thread->valgrind_stackid = VALGRIND_STACK_REGISTER(thread->uc.uc_stack.ss_sp, thread->uc.uc_stack.ss_sp + thread->uc.uc_stack.ss_size);
	thread->finished = 0;
  //contexte existe dèja !!
}

void launch(struct thread* thread, void* (*func)(void*), void* arg)
{
  void* return_value = func(arg);
  error("error creating thread");
  exit(1);
  thread->return_value = return_value;
}

int thread_create(thread_t* newthread, void* (*func)(void*), void* funcarg)
{
    if (!isinit) {
    queue__init(queue);

    init_main_thread()
    queue__add(queue, NULL); //!!!!
    isinit = 1;
  }
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
}launch, 3, thread, func, funcarg);

	*newthread = thread;
	return 0;
}