CC = gcc
CFLAGS = -Wall -g
VALGRIND_OPTIONS = --leak-check=full --show-reachable=yes --track-origins=yes
INCLUDE=

all: 

install:

test:

check: test

valgrind: test

pthreads: 

graphs: 


clean:
