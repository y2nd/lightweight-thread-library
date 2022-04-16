CC = gcc
CFLAGS = -Wall -O3 -Wextra -Wpedantic
VALGRIND_OPTIONS = --leak-check=full --show-reachable=yes --track-origins=yes -s

LIB_PATH=install/lib
BIN_PATH=install/bin

TST:=tst/01-main.c tst/02-switch.c tst/03-equity.c tst/11-join.c tst/12-join-main.c tst/21-create-many.c tst/22-create-many-recursive.c tst/23-create-many-once.c tst/31-switch-many.c tst/32-switch-many-join.c tst/33-switch-many-cascade.c tst/51-fibonacci.c #$(wildcard tst/*.c)
BINS:=$(TST:tst/%.c=$(BIN_PATH)/%)
BINS_PTHREAD:=$(TST:tst/%.c=$(BIN_PATH)/%-pthread)

STATIC_LIBRARY:=$(LIB_PATH)/libthread.a
DYNAMIC_LIBRARY:=$(LIB_PATH)/libthread.so

THREAD_LIBRARY=$(DYNAMIC_LIBRARY)

$(shell mkdir -p $(LIB_PATH) $(BIN_PATH))

define \n


endef

# Gestion des options
OPTIONS:=SCHED USE_CTOR Q_LOOP Q_MEM_POOL Q_MEM_POOL_G T_MEM_POOL T_MEM_POOL_G STATIC_LINK
SUFFIX:=

$(eval $(foreach OPTION,$(OPTIONS),ifdef $(OPTION)${\n}\
	SUFFIX:=-$(shell echo $(OPTION)_$($(OPTION)) | tr A-Z a-z)$$(SUFFIX)${\n}\
	CFLAGS:=-D$(OPTION)=$(shell echo $($(OPTION)) | tr a-z A-Z) $$(CFLAGS)${\n}\
endif${\n}\
))

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
	$(CC) $(CFLAGS) -Isrc -o $@ $^
$(BIN_PATH)/%-pthread: tst/%.c
	$(CC) $(CFLAGS) -Isrc -DUSE_PTHREAD $< -o $@ 

test: $(BINS)
	
check: test
	install/bin/01-main$(SUFFIX)
	install/bin/02-switch$(SUFFIX)
	install/bin/03-equity$(SUFFIX)
	install/bin/11-join$(SUFFIX)
	install/bin/12-join-main$(SUFFIX)
	install/bin/21-create-many$(SUFFIX) 1000
	install/bin/22-create-many-recursive$(SUFFIX) 1000
	install/bin/23-create-many-once$(SUFFIX) 1000
	install/bin/31-switch-many$(SUFFIX) 1000 1000
	install/bin/32-switch-many-join$(SUFFIX) 100 100
	install/bin/33-switch-many-cascade$(SUFFIX) 100 100
	install/bin/51-fibonacci$(SUFFIX) 20

valgrind: $(BINS)
	echo "****************************************"
	valgrind $(VALGRIND_OPTIONS) install/bin/01-main$(SUFFIX)
	echo "****************************************"
	valgrind $(VALGRIND_OPTIONS) install/bin/02-switch$(SUFFIX)
	echo "****************************************"
	valgrind $(VALGRIND_OPTIONS) install/bin/03-equity$(SUFFIX)
	echo "****************************************"
	valgrind $(VALGRIND_OPTIONS) install/bin/11-join$(SUFFIX)
	echo "****************************************"
	valgrind $(VALGRIND_OPTIONS) install/bin/12-join-main$(SUFFIX)
	echo "****************************************"
	valgrind $(VALGRIND_OPTIONS) install/bin/21-create-many$(SUFFIX) 1000
	echo "****************************************"
	valgrind $(VALGRIND_OPTIONS) install/bin/22-create-many-recursive$(SUFFIX) 1000
	echo "****************************************"
	valgrind $(VALGRIND_OPTIONS) install/bin/23-create-many-once$(SUFFIX) 1000
	echo "****************************************"
	valgrind $(VALGRIND_OPTIONS) install/bin/31-switch-many$(SUFFIX) 1000 1000
	echo "****************************************"
	valgrind $(VALGRIND_OPTIONS) install/bin/32-switch-many-join$(SUFFIX) 100 100
	echo "****************************************"
	valgrind $(VALGRIND_OPTIONS) install/bin/33-switch-many-cascade$(SUFFIX) 100 100
	echo "****************************************"
	valgrind $(VALGRIND_OPTIONS) install/bin/51-fibonacci$(SUFFIX) 20

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
	install/bin/51-fibonacci$(SUFFIX)-pthread 20

graphs: $(BINS) $(BINS_PTHREAD)
	graphs/plot.sh

.PHONY: all test clean install graphs valgrind

clean:
	rm -rf *.o *.so install/bin/ install/lib/