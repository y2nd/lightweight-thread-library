#include "thread.h"

#include "config.h"

#include "queue.h"
#include <bits/types/sigset_t.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/ucontext.h>
#include <ucontext.h> /* ne compile pas avec -std=c89 ou -std=c99 */
#include <valgrind/valgrind.h>
#include <errno.h>
#include <stdint.h>
#include <time.h>
#include <signal.h>
#include <unistd.h>

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

#define STACK_SIZE 64 * 1024

struct thread {
	ucontext_t uc;
	int valgrind_stackid;
	void* return_value; // Ou next
	int finished;
#if SCHED == FIFO || SCHED == ECONOMY
	struct thread* joiner; // Le thread qui attend notre fin
#endif
#if SCHED == ECONOMY
	int joining; // Wether the thread is waiting for another to finish
#endif
	const char stack[STACK_SIZE];
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
int nb_threads = 1;
int is_initialized = 0;

struct thread main_thread;

static int force_thread_yield();

#if PREEMPT
// TODO PREEMPT (rapport)-> faire des tests de perf avec une variable globale à la place de sigprocmask pour block et unblock
// (devrait générer un problème où il faut unblock dès qu'on arrive sur le thread)
// + tests perfs avec timer en 1 ms et 100 ms (facteur de temps ?)
// + comparaison interval/reset

timer_t timerid;
int has_yielded = 0;

static int force_thread_yield_impl();

void handler(int i)
{
	#if TIMER_INTERVAL
	if (has_yielded) {
		has_yielded = 0;
		return;
	} else {
		has_yielded = 1;
		(void)i;
		printf("Handler called\n");
		force_thread_yield_impl();
	}
	#endif
	#if !TIMER_INTERVAL
	(void)i;
	printf("Handler called\n");
	force_thread_yield_impl();
	#endif
}

sigset_t sigset;

void set_time()
{
	struct itimerspec its;
	long long freq_nanosecs;

	freq_nanosecs = 100000000; // 100 ms
	its.it_value.tv_sec = freq_nanosecs / 1000000000;
	its.it_value.tv_nsec = freq_nanosecs % 1000000000;
	#if TIMER_INTERVAL
	// preemt if no thread has yield on the given interval, else no yield on next end of interval
	its.it_interval.tv_sec = its.it_value.tv_sec;
	its.it_interval.tv_nsec = its.it_value.tv_nsec;
	#endif
	#if !TIMER_INTERVAL
	// default (if no interval) is reset timer for every thread
	its.it_interval.tv_sec = 0;
	its.it_interval.tv_nsec = 0;
	#endif

	if (timer_settime(timerid, 0, &its, NULL) == -1)
		error("timer_settime");
}

void block_preempt()
{
	if (sigprocmask(SIG_BLOCK, &sigset, NULL) != 0)
		error("sigprocmask block");
}

void unblock_preempt()
{
	if (sigprocmask(SIG_UNBLOCK, &sigset, NULL) != 0)
		error("sigprocmask blunblockock");
}

#endif

static void DESTRUCTOR release_main_thread()
{
#if PREEMPT
	timer_delete(&timerid);
#endif

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

#if SCHED == FIFO || SCHED == ECONOMY
		main_thread.joiner = NULL;
#endif
#if SCHED == ECONOMY
		main_thread.joining = 0;
#endif

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

#if PREEMPT
		sigemptyset(&sigset);
		sigaddset(&sigset, SIG);

		struct sigaction sa;
		sa.sa_flags = 0;
		sa.sa_handler = handler;
		sigemptyset(&sa.sa_mask);
		if (sigaction(SIG, &sa, NULL) == -1)
			error("sigaction");

		struct sigevent sev;
		sev.sigev_signo = SIG;
		sev.sigev_value.sival_ptr = &timerid;
		sev.sigev_notify = SIGEV_SIGNAL;
		if (timer_create(CLOCKID, &sev, &timerid) == -1)
			error("timer_create");

		set_time();
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

static int thread_semi_join(struct thread* _thread);

int thread_create(thread_t* newthread, void* (*func)(void*), void* funcarg)
{
	INIT_QUEUE_IF_NEEDED_RETURN;

#if PREEMPT
	block_preempt();
#endif

	nb_threads++;

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
			while (threads.last_pool_size > 0) {
				threads.last_pool_size /= 2;
				threads.last_pool->next = malloc(sizeof(struct thread_pool) + threads.last_pool_size * sizeof(struct thread));
				if (threads.last_pool->next)
					goto size_ok_thread;
			}
			printf("thread_create erreur malloc\n");
			return -1;
		}
	size_ok_thread:
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
	thread->uc.uc_stack.ss_size = STACK_SIZE;
	thread->uc.uc_stack.ss_sp = (void*)thread->stack;
	if (!thread->uc.uc_stack.ss_sp) {
		error("thread_create malloc is null");
		return -1;
	}
#if SCHED == FIFO || SCHED == ECONOMY
	thread->joiner = NULL;
#endif
#if SCHED == ECONOMY
	thread->joining = 0;
#endif
	thread->uc.uc_link = NULL; // WARN : (sizeof(ucontext_t));
	thread->valgrind_stackid = VALGRIND_STACK_REGISTER(thread->uc.uc_stack.ss_sp, thread->uc.uc_stack.ss_sp + thread->uc.uc_stack.ss_size);
	thread->finished = 0;

	*newthread = thread;

	makecontext(&thread->uc, (void (*)(void))launch, 2, func, funcarg);

	queue__add(&queue, thread);

#if PREEMPT
	unblock_preempt();
#endif

	if (nb_threads > THREAD_LIMIT) {
		int code;
		if ((code = thread_semi_join(thread)))
			return code;
	}

	return 0;
}

int thread_yield(void)
{
	return force_thread_yield();
}

static int force_thread_yield_impl(void)
{
	INIT_QUEUE_IF_NEEDED_RETURN;

	if (!queue__has_one_element(&queue)) {
		struct thread* thread_before = (struct thread*)queue__top(&queue);

		queue__roll(&queue);

		struct thread* thread_next = (struct thread*)queue__top(&queue);
#if SCHED == ECONOMY
		while (thread_next->joining != 0) {
			queue__roll(&queue);
			thread_next = (struct thread*)queue__top(&queue);
		}
#endif
		if (swapcontext(&(thread_before->uc), &thread_next->uc) != 0) {
			error("force_thread_yield swapcontext");
			return -1;
		}
#if PREEMPT
		set_time();
#endif
	}
	return 0;
}

static int force_thread_yield(void)
{
#if PREEMPT
	block_preempt();
#endif

	int code = force_thread_yield_impl();

#if PREEMPT
	unblock_preempt();
#endif

	return code;
}

/* Waits for end but does not take return value */
static int thread_semi_join(struct thread* _thread)
{
#if PREEMPT
	block_preempt();
#endif

#if SCHED == BASIC
	while (_thread->finished != 1)
		force_thread_yield();
#elif SCHED == FIFO || SCHED == ECONOMY
	if (_thread->finished != 1) {
	#if SCHED == FIFO
		_thread->joiner = queue__pop(&queue); // Le joiner s'enlève de la file
		if (swapcontext(&(_thread->joiner->uc), &((struct thread*)queue__top(&queue))->uc) != 0) {
			error("thread_join swapcontext");
			return -1;
		}
		#if PREEMPT
		set_time();
		#endif
	#elif SCHED == ECONOMY
		_thread->joiner = queue__top(&queue);
		struct thread* self = thread_self();
		self->joining = 1;
		force_thread_yield();
	#endif
	}
#endif

#if PREEMPT
	unblock_preempt();
#endif

	return 0;
}

int thread_join(thread_t thread, void** retval)
{
	struct thread* _thread = (struct thread*)thread;
	int code;
	if ((code = thread_semi_join(_thread)))
		return code;

	nb_threads--;

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
#if PREEMPT
	block_preempt();
#endif

	struct thread* thread = queue__top(&queue);

	int last_element;

#if SCHED == BASIC || SCHED == ECONOMY
	last_element = queue__has_one_element(&queue);
	#if SCHED == ECONOMY
	if (thread->joiner) {
		thread->joiner->joining = 0;
	}
	#endif
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

			struct thread* thread_next = ((struct thread*)queue__top(&queue));
#if SCHED == ECONOMY
			while (thread_next->joining != 0) {
				queue__roll(&queue);
				thread_next = (struct thread*)queue__top(&queue);
			}
#endif

			if (swapcontext(&main_thread.uc, &thread_next->uc) != 0) {
				error("thread_exit swapcontext");
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

			struct thread* thread_next = ((struct thread*)queue__top(&queue));
#if SCHED == ECONOMY
			while (thread_next->joining != 0) {
				queue__roll(&queue);
				thread_next = (struct thread*)queue__top(&queue);
			}
#endif

			if (setcontext(&thread_next->uc) != 0) {
				error("thread_exit set_context");
			}
			exit(-1);
		}
	}

	exit(-1);
}

#include <assert.h>

/* Mutex */
int thread_mutex_init(thread_mutex_t* mutex)
{
	mutex->dummy = 0; // default value for mutex
#if SCHED == FIFO || SCHED == ECONOMY
	queue__init(&mutex->queue, NULL);
#endif
	return 0;
}

int thread_mutex_destroy(thread_mutex_t* mutex)
{
	mutex->dummy = -1; // invalid value for mutex
#if SCHED == FIFO || SCHED == ECONOMY
	queue__release(&mutex->queue);
#endif
	return 0;
}

int thread_mutex_lock(thread_mutex_t* mutex)
{
#if SCHED == BASIC
	/* yield until mutex is unlocked */
	while (mutex->dummy)
		thread_yield();
#elif SCHED == FIFO || SCHED == ECONOMY
	/* if mutex is locked */
	if (mutex->dummy) {
		struct thread* self = queue__pop(&queue);
	#if SCHED == ECONOMY
		self->joining = 1; // TODO: debug infinite loop
	#endif
		queue__add(&mutex->queue, self);

		if (swapcontext(&(self->uc), &((struct thread*)queue__top(&queue))->uc) != 0) {
			error("thread_mutex_lock swapcontext");
			return -1;
		}
	}
#endif
	/* lock mutex */
	mutex->dummy = 1;
	return 0;
}

int thread_mutex_unlock(thread_mutex_t* mutex)
{
#if SCHED == BASIC
	/* unlock mutex */
	mutex->dummy = 0;
	return 0;
#elif SCHED == FIFO || SCHED == ECONOMY
	#if SCHED == ECONOMY
	struct thread* self = thread_self();
	self->joining = 0;
	#endif
	/* check if queue is e_m_p_t_y  */
	if (queue__has_one_element(&mutex->queue)) {
		/* unlock mutex */
		mutex->dummy = 0;
	} else {
		if (queue__top(&mutex->queue) == NULL)
			queue__roll(&mutex->queue);
		struct thread* next = queue__pop(&mutex->queue);
		queue__add(&queue, next);
	#if SCHED == ECONOMY
		next->joining = 0;
	#endif
	}
	return 0;
#endif
}
