CC := gcc
CFLAGS := -Ofast -march=native -flto -Wno-clobbered
VALGRIND_OPTIONS := --leak-check=full --show-reachable=yes --track-origins=yes -s

LIB_PATH:=install/lib
BIN_PATH:=install/bin

TST:=tst/01-main.c tst/02-switch.c tst/03-equity.c tst/11-join.c tst/12-join-main.c tst/21-create-many.c tst/22-create-many-recursive.c tst/23-create-many-once.c tst/31-switch-many.c tst/32-switch-many-join.c tst/33-switch-many-cascade.c tst/44-reduction.c tst/51-fibonacci.c tst/61-mutex.c tst/62-mutex.c tst/71-preemption.c tst/77-merge-sort.c #$(wildcard tst/*.c)
BINS:=$(TST:tst/%.c=$(BIN_PATH)/%)
BINS_PTHREAD:=$(TST:tst/%.c=$(BIN_PATH)/%-pthread)

$(shell mkdir -p $(LIB_PATH) $(BIN_PATH))

define \n


endef

# Gestion des options
OPTIONS:=SCHED USE_CTOR Q_LOOP Q_MEM_POOL Q_MEM_POOL_G T_MEM_POOL T_MEM_POOL_G
SUFFIX:=

$(eval $(foreach OPTION,$(OPTIONS),ifdef $(OPTION)${\n}\
	SUFFIX:=-$(shell echo $(OPTION)_$($(OPTION)) | tr A-Z a-z)$$(SUFFIX)${\n}\
	CFLAGS:=-D$(OPTION)=$(shell echo $($(OPTION)) | tr a-z A-Z) $$(CFLAGS)${\n}\
endif${\n}\
))

THREAD_LIBRARY=$(STATIC_LIBRARY)
LIBRARY_OPTIONS=$(LIB_PATH)/libthread$(SUFFIX).a

ifdef STATIC_LINKING
	THREAD_LIBRARY=$(STATIC_LIBRARY)
	LIBRARY_OPTIONS=$(LIB_PATH)/libthread$(SUFFIX).a
	SUFFIX:=$(SUFFIX)-static
endif

ifdef DYNAMIC_LINKING
	THREAD_LIBRARY=$(DYNAMIC_LIBRARY)
	LIBRARY_OPTIONS=-L$(LIB_PATH) -lthread$(SUFFIX)
	SUFFIX:=$(SUFFIX)-dynamic
endif

ifdef MAX_OPTI
	SUFFIX:=$(SUFFIX)-max_opti
	LIBRARY_OPTIONS:=src/thread.c src/queue.c
endif

ifdef NORMAL_OPTI
	CFLAGS:= -Wall -O3 -Wextra -Wpedantic -Wno-clobbered
	SUFFIX:=$(SUFFIX)-normal_opti
endif

ifdef DEBUG
	CFLAGS:= -Wall -Wextra -Wpedantic -Wno-clobbered -Og -ggdb3
	SUFFIX:=$(SUFFIX)-debug
endif

BINS:=$(BINS:$(BIN_PATH)/%=$(BIN_PATH)/%$(SUFFIX))
STATIC_LIBRARY:=$(LIB_PATH)/libthread$(SUFFIX).a
DYNAMIC_LIBRARY:=$(LIB_PATH)/libthread$(SUFFIX).so

all: install test

$(STATIC_LIBRARY): src/thread.c src/queue.c
	$(CC) $(CFLAGS) -c src/thread.c -o thread.o -Isrc
	$(CC) $(CFLAGS) -c src/queue.c  -o queue.o -Isrc
	ar rc $@ thread.o queue.o

$(DYNAMIC_LIBRARY): src/thread.c src/queue.c
	$(CC) $(CFLAGS) -c -fPIC src/thread.c -o thread.o -Isrc
	$(CC) $(CFLAGS) -c -fPIC src/queue.c  -o queue.o -Isrc
	$(CC) $(CFLAGS) thread.o queue.o -shared -o $(DYNAMIC_LIBRARY)

install: $(BINS) $(BINS_PTHREAD)

$(BIN_PATH)/%$(SUFFIX): tst/%.c $(THREAD_LIBRARY)
#	$(CC) $(CFLAGS) -Isrc -o $@ -L$(LIB_PATH) $< -lthread  
	$(CC) $(CFLAGS) -Isrc -o $@ $< $(LIBRARY_OPTIONS)
$(BIN_PATH)/%-pthread: tst/%.c
	$(CC) $(CFLAGS) -Isrc -DUSE_PTHREAD $< -o $@ -lpthread

test: $(BINS)
	
check: test
	LD_LIBRARY_PATH=install/lib install/bin/01-main$(SUFFIX)
	LD_LIBRARY_PATH=install/lib install/bin/02-switch$(SUFFIX)
	LD_LIBRARY_PATH=install/lib install/bin/03-equity$(SUFFIX)
	LD_LIBRARY_PATH=install/lib install/bin/11-join$(SUFFIX)
	LD_LIBRARY_PATH=install/lib install/bin/12-join-main$(SUFFIX)
	LD_LIBRARY_PATH=install/lib install/bin/21-create-many$(SUFFIX) 1000
	LD_LIBRARY_PATH=install/lib install/bin/22-create-many-recursive$(SUFFIX) 1000
	LD_LIBRARY_PATH=install/lib install/bin/23-create-many-once$(SUFFIX) 1000
	LD_LIBRARY_PATH=install/lib install/bin/31-switch-many$(SUFFIX) 1000 1000
	LD_LIBRARY_PATH=install/lib install/bin/32-switch-many-join$(SUFFIX) 100 100
	LD_LIBRARY_PATH=install/lib install/bin/33-switch-many-cascade$(SUFFIX) 100 100
	LD_LIBRARY_PATH=install/lib install/bin/44-reduction$(SUFFIX)
	LD_LIBRARY_PATH=install/lib install/bin/51-fibonacci$(SUFFIX) 20
	LD_LIBRARY_PATH=install/lib install/bin/61-mutex$(SUFFIX) 20
	LD_LIBRARY_PATH=install/lib install/bin/62-mutex$(SUFFIX) 20
	LD_LIBRARY_PATH=install/lib install/bin/71-preemption$(SUFFIX) 25
	LD_LIBRARY_PATH=install/lib install/bin/77-merge-sort$(SUFFIX)

valgrind: $(BINS)
	echo "****************************************"
	LD_LIBRARY_PATH=install/lib valgrind $(VALGRIND_OPTIONS) install/bin/01-main$(SUFFIX)
	echo "****************************************"
	LD_LIBRARY_PATH=install/lib valgrind $(VALGRIND_OPTIONS) install/bin/02-switch$(SUFFIX)
	echo "****************************************"
	LD_LIBRARY_PATH=install/lib valgrind $(VALGRIND_OPTIONS) install/bin/03-equity$(SUFFIX)
	echo "****************************************"
	LD_LIBRARY_PATH=install/lib valgrind $(VALGRIND_OPTIONS) install/bin/11-join$(SUFFIX)
	echo "****************************************"
	LD_LIBRARY_PATH=install/lib valgrind $(VALGRIND_OPTIONS) install/bin/12-join-main$(SUFFIX)
	echo "****************************************"
	LD_LIBRARY_PATH=install/lib valgrind $(VALGRIND_OPTIONS) install/bin/21-create-many$(SUFFIX) 1000
	echo "****************************************"
	LD_LIBRARY_PATH=install/lib valgrind $(VALGRIND_OPTIONS) install/bin/22-create-many-recursive$(SUFFIX) 1000
	echo "****************************************"
	LD_LIBRARY_PATH=install/lib valgrind $(VALGRIND_OPTIONS) install/bin/23-create-many-once$(SUFFIX) 1000
	echo "****************************************"
	LD_LIBRARY_PATH=install/lib valgrind $(VALGRIND_OPTIONS) install/bin/31-switch-many$(SUFFIX) 1000 1000
	echo "****************************************"
	LD_LIBRARY_PATH=install/lib valgrind $(VALGRIND_OPTIONS) install/bin/32-switch-many-join$(SUFFIX) 100 100
	echo "****************************************"
	LD_LIBRARY_PATH=install/lib valgrind $(VALGRIND_OPTIONS) install/bin/33-switch-many-cascade$(SUFFIX) 100 100
	echo "****************************************"
	# LD_LIBRARY_PATH=install/lib valgrind $(VALGRIND_OPTIONS) install/bin/44-reduction$(SUFFIX)
	echo "****************************************"
	# LD_LIBRARY_PATH=install/lib valgrind $(VALGRIND_OPTIONS) install/bin/51-fibonacci$(SUFFIX) 20
	echo "****************************************"
	LD_LIBRARY_PATH=install/lib valgrind $(VALGRIND_OPTIONS) install/bin/61-mutex$(SUFFIX) 20
	echo "****************************************"
	LD_LIBRARY_PATH=install/lib valgrind $(VALGRIND_OPTIONS) install/bin/62-mutex$(SUFFIX) 20


pthreads: $(BINS_PTHREAD)
	install/bin/01-main$(SUFFIX)-pthread
	install/bin/02-switch$(SUFFIX)-pthread
	install/bin/03-equity$(SUFFIX)-pthread
	install/bin/11-join$(SUFFIX)-pthread
	install/bin/12-join-main$(SUFFIX)-pthread
	install/bin/21-create-many$(SUFFIX)-pthread 1000
	install/bin/22-create-many-recursive$(SUFFIX)-pthread 1000
	install/bin/23-create-many-once$(SUFFIX)-pthread 1000
	install/bin/31-switch-many$(SUFFIX)-pthread 1000 1000
	install/bin/32-switch-many-join$(SUFFIX)-pthread 100 100
	install/bin/33-switch-many-cascade$(SUFFIX)-pthread 100 100
	install/bin/44-reduction$(SUFFIX)-pthread
	install/bin/51-fibonacci$(SUFFIX)-pthread 20
	install/bin/61-mutex$(SUFFIX)-pthread 20
	install/bin/62-mutex$(SUFFIX)-pthread 20

graphs: $(BINS) $(BINS_PTHREAD)
	graphs/plot.sh

clean_graphs:
	rm -rf graphs/data* graphs/*.png

.PHONY: all test clean install graphs valgrind

clean:
	rm -rf *.o *.so install/bin/ install/lib/