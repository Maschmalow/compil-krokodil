LEX=flex
YACC=bison
CFLAGS=-Wall -std=c99 -D_GNU_SOURCE
CC=gcc

all:parse

parse:grammar.c scanner.c types.c data.c
	$(CC) $(CFLAGS) -o $@ $^

grammar.c:grammar.y
	$(YACC) -d -o $@ --defines=grammar.tab.h $^

%.c:%.l
	$(LEX) -o $@ $^
    

clean:
	rm -f grammar.c scanner.c parse
