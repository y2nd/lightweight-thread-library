CC = gcc
CFLAGS = -Wall -O3 -Wextra -Wpedantic
VALGRIND_OPTIONS = --leak-check=full --show-reachable=yes --track-origins=yes

LIB_PATH=install/lib
BIN_PATH=install/bin

BINS:= $(wildcard tst/*.c)
BINS_PTHREAD:= $(BINS)
BINS:=$(BINS:tst/%.c=$(BIN_PATH)/%)
BINS_PTHREAD:=$(BINS_PTHREAD:tst/%.c=$(BIN_PATH)/%-pthread)

$(shell  mkdir -p $(LIB_PATH) $(BIN_PATH))

all: install test

$(LIB_PATH)/libthread.a: src/thread.c src/queue.c
	$(CC) $(CFLAGS) -c src/thread.c -o thread.o -Isrc
	$(CC) $(CFLAGS) -c src/queue.c  -o queue.o -Isrc
	ar rc $@ thread.o queue.o

$(LIB_PATH)/libthread.so: src/thread.c src/queue.c
	$(CC) $(CFLAGS) -c -fPIC src/thread.c -o thread.o -Isrc
	$(CC) $(CFLAGS) -c -fPIC src/queue.c  -o queue.o -Isrc
	$(CC) $(CFLAGS) thread.o queue.o -shared -o $(LIB_PATH)/libthread.so

install: $(LIB_PATH)/libthread.a

$(BIN_PATH)/%: tst/%.c $(LIB_PATH)/libthread.a
#	$(CC) $(CFLAGS) -Isrc -o $@ -L$(LIB_PATH) $< -lthread  
	$(CC) $(CFLAGS) -Isrc -o $@ $^
$(BIN_PATH)/%-pthread: tst/%.c
	$(CC) $(CFLAGS) -Isrc -DUSE_PTHREAD $< -o $@ 

test: $(BINS)
	
check: test
	install/bin/01-main
	install/bin/02-switch
	install/bin/03-equity
	install/bin/11-join
	install/bin/12-join-main
	install/bin/21-create-many 1000
	install/bin/22-create-many-recursive 1000
	install/bin/23-create-many-once 1000
	install/bin/31-switch-many 1000
	install/bin/32-switch-many-join 100
	install/bin/33-switch-many-cascade 100
	install/bin/51-fibonacci 20

valgrind: test
	for x in ./install/bin/*; do echo "********************$$x********************"; valgrind $(VALGRIND_OPTIONS) $$x; done

pthreads: $(BINS_PTHREAD)
	for x in ./install/bin/*-pthread; do echo $$x; $$x; done

graphs: $(BINS) $(BINS_PTHREAD)
	python graphs/plot.py

.PHONY: all test clean install graphs

clean:
	rm -rf *.o *.so install/bin/ install/lib/