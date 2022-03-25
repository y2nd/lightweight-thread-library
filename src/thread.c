#include <stdio.h>
#include <stdlib.h>
#include <sys/ucontext.h>
#include <ucontext.h> /* ne compile pas avec -std=c89 ou -std=c99 */
#include <unistd.h>

#include "thread.h"




//waiting list, the head of the list is the current runner

struct thread * current_th;//the queu of this thread a waiting to be executed.

struct thread{
  ucontext_t uc;
  //int num_th;
  struct stread * next;
};




void func(int  numero)
{
  printf("j'affiche le numéro %d\n", numero);
}



//the id of the current thread 
thread_t thread_self(){
  return (thread_t)current_th;
}


//We assume that a malloc newthead has already be done
int thread_create(thread_t *newthread, void *(*func)(void *), void *funcarg){
    

    struct thread  * * tr = (struct thread  * *)newthread;
    
    int ret = getcontext(&(*tr)->uc);
    (*tr)->uc.uc_stack.ss_size = 64*1024;
    (*tr)->uc.uc_stack.ss_sp = malloc((*tr)->uc.uc_stack.ss_size);

    (*tr)->uc.uc_link = NULL;
    
    /*This belongs in the test function

    makecontext(&(*tr)->uc, (void (*)(void)) func, 1, *(int *)funcarg);
     printf("je suis dans la fonction appelant le thread\n");
    setcontext((&(*tr)->uc));
    printf("Je pars sans revenir\n");
    */

    * newthread = tr;

    return ret;

}



/*
To test the function thread_create//
*/
void test_thread_create(){
  int arg = 5;
  struct thread * t = malloc(sizeof(struct thread));

  thread_create((thread_t *)(&t), (void* (*)(void*)) func , (void *)&arg);
  free(t);
  
}



int main() {
  
  ucontext_t uc, previous;

  getcontext(&uc); /* initialisation de uc avec valeurs coherentes
		    * (pour éviter de tout remplir a la main ci-dessous) */

  
  uc.uc_stack.ss_size = 64*1024;
  uc.uc_stack.ss_sp = malloc(uc.uc_stack.ss_size);
  uc.uc_link = &previous;
  makecontext(&uc, (void (*)(void)) func, 1, 34);

  
  
  printf("je suis dans le main\n");
  printf("My adresse is %p", &uc);
  swapcontext(&previous, &uc);
  printf("je suis revenu dans le main\n");
  free(uc.uc_stack.ss_sp);
  
  /*
  uc.uc_stack.ss_size = 64*1024;
  uc.uc_stack.ss_sp = malloc(uc.uc_stack.ss_size);
  uc.uc_link = NULL;
  makecontext(&uc, (void (*)(void)) func, 1, 57);


  printf("je suis dans le main bis\n");
  printf("Danas le main l'adresse est %p\n", &uc);
  setcontext(&uc);
  printf("je ne reviens jamais ici\n");
  */


  return 0;
}

