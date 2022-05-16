#ifndef __CONFIG_H__
#define __CONFIG_H__

#include "config_constants.h"

/* Configuration du projet */
/* Ce document met en place des valeurs par défaut pour les macros de configuration du projet
   et vérifie qu'elles ont une valeur cohérente */

/* SCHED utilisé */
/* Value :
	- BASIC : les threads qui join ne quittent pas la file et yield en boucle jusqu'à ce que leur cible se finit
	- FIFO : les threads qui join quittent la file et rejoignent la fin de file quand leur cible se finit
	- ECONOMY : comme BASIC mais on check si le thread est en attente avant de swapcontext dessus
*/
#ifndef SCHED
	#define SCHED FIFO
#endif

/* Use Preemption */
/*
	- NO : Don't use it
	- YES : use it
*/
#ifndef PREEMPT
	#define PREEMPT YES
#endif
#ifndef TIMER_INTERVAL
	#define TIMER_INTERVAL YES
#endif
#ifndef CLOCKID
	#define CLOCKID CLOCK_MONOTONIC
#endif
#ifndef SIG
	#define SIG SIGUSR1
#endif

/* Use constructor/destructor attribute */
/* Value :
	- NO : Don't use it
	- YES : Use it if possible
	- FORCE : Force use it (if not possible => error)
*/
#ifndef USE_CTOR
	#define USE_CTOR YES
#endif

/* end.next == top pour la file */
/* Value : NO or YES */
#ifndef Q_LOOP
	#define Q_LOOP YES
#endif

/* Memory Pool pour les éléments de la queue */
/* Value : 0 or 1 */
/* Growth Value : constant, linear or exponential */
#ifndef Q_MEM_POOL
	#define Q_MEM_POOL YES
#endif
#ifndef Q_MEM_POOL_G
	#define Q_MEM_POOL_G EXPONENTIAL
#endif
#ifndef Q_MEM_POOL_FS
	#define Q_MEM_POOL_FS 10
#endif

/* Memory Pool pour les threads */
/* Value : 0 or 1 */
/* Growth Value : constant, linear or exponential */
#ifndef T_MEM_POOL
	#define T_MEM_POOL YES
#endif
#ifndef T_MEM_POOL_G
	#define T_MEM_POOL_G EXPONENTIAL
#endif
#ifndef T_MEM_POOL_FS
	#define T_MEM_POOL_FS 10
#endif

/* Number of threads before create directly joins the thread */
#define THREAD_LIMIT 1000

#include "config_verifs.h"

#endif /* __CONFIG_H__ */
