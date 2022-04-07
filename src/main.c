#include "thread.h"

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <inttypes.h>

void* function1(void* arg)
{
	printf("Function %" PRIuPTR "\n", (intptr_t)arg);
	thread_yield();
	return NULL;
}

int main()
{
	thread_yield();

	printf("%p\n", thread_self());

	thread_t thread, thread2;
	thread_create(&thread, function1, (void*)1);
	thread_create(&thread2, function1, (void*)2);

	thread_yield();
	thread_yield();

	void* retval;
	thread_join(thread2, &retval);
	printf("Function %" PRIuPTR "\n", (intptr_t)retval);

	thread_join(thread, &retval);
	printf("Function %" PRIuPTR "\n", (intptr_t)retval);

	return EXIT_SUCCESS;
}