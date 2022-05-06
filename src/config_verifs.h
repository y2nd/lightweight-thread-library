#ifndef __CONFIG_VERIFS_H__
#define __CONFIG_VERIFS_H__

#if SCHED != BASIC && SCHED != FIFO && SCHED != ECONOMY
	#error Wrong value for SCHED
#endif

#if PREEMPT != NO && PREEMPT != YES
	#error Wrong value for PREEMPT
#endif

#if USE_CTOR != NO && USE_CTOR != YES && USE_CTOR != FORCE
	#error Wrong value for USE_CTOR
#endif

#if Q_LOOP != NO && Q_LOOP != YES
	#error Wrong value for Q_LOOP
#endif

#if Q_MEM_POOL != NO && Q_MEM_POOL != YES
	#error Wrong value for Q_MEM_POOL
#endif
#if Q_MEM_POOL
	#if Q_MEM_POOL_G != CONSTANT && Q_MEM_POOL_G != LINEAR && Q_MEM_POOL_G != EXPONENTIAL
		#error Wrong value for Q_MEM_POOL_G
	#endif
#endif

#if T_MEM_POOL != NO && T_MEM_POOL != YES
	#error Wrong value for T_MEM_POOL
#endif
#if T_MEM_POOL
	#if T_MEM_POOL_G != CONSTANT && T_MEM_POOL_G != LINEAR && T_MEM_POOL_G != EXPONENTIAL
		#error Wrong value for T_MEM_POOL_G
	#endif
#endif

#endif /* __CONFIG_VERIFS_H__ */
