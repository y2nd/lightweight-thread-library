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
	$(CC) -c src/thread.c -o thread.o -Isrc
	$(CC) -c src/queue.c  -o queue.o -Isrc
	ar rc $@ thread.o queue.o

$(LIB_PATH)/libthread.so: src/thread.c src/queue.c
	$(CC) -c -fPIC src/thread.c -o thread.o -Isrc
	$(CC) -c -fPIC src/queue.c  -o queue.o -Isrc
	$(CC) thread.o queue.o -shared -o $(LIB_PATH)/libthread.so

install: $(LIB_PATH)/libthread.a

$(BIN_PATH)/%: tst/%.c $(LIB_PATH)/libthread.a
#	$(CC) -Isrc $(CFLAGS) -o $@ -L$(LIB_PATH) $< -lthread  
	$(CC) -Isrc $(CFLAGS) -o $@ $^
$(BIN_PATH)/%-pthread: tst/%.c
	$(CC) -Isrc $(CFLAGS) -DUSE_PTHREAD $< -o $@ 
	
test: $(BINS)
	
check: test
	for x in ./install/bin/*; do echo $$x; $$x; done

valgrind: test
	for x in ./install/bin/*; do echo "********************$$x********************"; valgrind $(VALGRIND_OPTIONS) $$x; done

pthreads: $(BINS_PTHREAD)
	for x in ./install/bin/*-pthread; do echo $$x; $$x; done

graphs: $(BINS) $(BINS_PTHREAD)
	python graphs/plot.py

.PHONY: all test clean install graphs

clean:
	rm -rf *.o *.so install/bin/ install/lib/