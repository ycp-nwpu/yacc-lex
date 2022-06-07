all: syntaxtree

syntaxtree: lex.yy.c y.tab.c
    cc lex.yy.c y.tab.c -o syntaxtree -ll -ly -I./ -std=c11

lex.yy.c: syntaxtree.lex
    lex syntaxtree.lex

y.tab.c:
    yacc syntaxtree.y -d

clean:
    rm lex.yy.c -f
    rm y.tab.c -f
    rm y.tab.h -f
    rm syntaxtree -f
.PHONY: clean
