%{
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include "node.h"

Node *opr(int name, int num, ...);

Node *set_index(int value);
Node *set_content(int value);

void freeNode(Node *p);
int execNode(Node *p);
int yylexeNode();

void yyerror(char *s);

int memory[26];
%}

%union {
    int ivalue; // variable's value.
    int sindex; // variable array's index.
    Node *nptr; // node address.
};

%token <ivalue> VARIABLE
%token <sindex> INTEGER
%token WHILE IF PRINT

%nonassoc IFX
%nonassoc ELSE

%left AND OR GE LE EQ NE GT LT
%left '+' '-'
%left '*' '/' '%'

%nonassoc UMINUS NOT
%type <nptr> stmt expr stmt_list

%%

program:
    function { exit(0); }
    ;

function:
    function stmt { execNode($2); freeNode($2); }
    | /* null statement. */
    ;

stmt:
    ';' { $$ = opr(';', 2, NULL, NULL); }
    | expr ';' { $$ = $1; }
    | PRINT expr ';' { $$ = opr(PRINT, 1, $2); }
    | VARIABLE '=' expr ';' { $$ = opr('=', 2, set_index($1), $3); }
    | WHILE '(' expr ')' stmt { $$ = opr(WHILE, 2, $3, $5); }
    | IF '(' expr ')' stmt %prec IFX { $$ = opr(IF, 2, $3, $5); }
    | IF '(' expr ')' stmt ELSE stmt %prec ELSE { $$ = opr(IF, 3, $3, $5, $7); }
    | '{' stmt_list '}' { $$ = $2; }
    ;

stmt_list:
    stmt { $$ = $1; }
    | stmt_list stmt { $$ = opr(';', 2, $2, $1); }
    ;

expr:
    INTEGER { $$ = set_content($1); }
    | VARIABLE { $$ = set_index($1); }
    | expr '+' expr { $$ = opr('+', 2, $1, $3); }
    | expr '-' expr { $$ = opr('-', 2, $1, $3); }
    | expr '*' expr { $$ = opr('*', 2, $1, $3); }
    | expr '/' expr { $$ = opr('/', 2, $1, $3); }
    | expr '%' expr { $$ = opr('%', 2, $1, $3); }
    | expr GT expr { $$ = opr(GT, 2, $1, $3); }
    | expr GE expr { $$ = opr(GE, 2, $1, $3); }
    | expr LE expr { $$ = opr(LE, 2, $1, $3); }
    | expr LT expr { $$ = opr(LT, 2, $1, $3); }
    | expr NE expr { $$ = opr(NE, 2, $1, $3); }
    | expr EQ expr { $$ = opr(EQ, 2, $1, $3); }
    | expr AND expr { $$ = opr(AND, 2, $1, $3); }
    | expr OR expr { $$ = opr(OR, 2, $1, $3); }
    | NOT expr %prec NOT { $$ = opr(NOT, 1, $2); }
    | '-' expr %prec UMINUS { $$ = opr(UMINUS, 1, $2); }
    | '(' expr ')' { $$ = $2; }
    ;

%%

#define SIZE_OF_HEAD ((char *)&p->content-(char *)p)

Node *set_content(int value)
{
    Node *p;
    size_t nsize = SIZE_OF_HEAD + sizeof(int);
    if((p = malloc(nsize)) == NULL) {
        yyerror("out of memory @ set_content.\n");
    }
    p->type = TYPE_CONTENT;
    p->content = value;

    return p;
}

Node *set_index(int value)
{
    Node *p;
    size_t nsize = SIZE_OF_HEAD + sizeof(int);
    if((p = malloc(nsize)) == NULL) {
        yyerror("out of memory @ set_index.\n");
    }
    p->type = TYPE_INDEX;
    p->index = value;

    return p;
}

Node *opr(int name, int num, ...)
{
    va_list ap;
    Node *p;
    size_t nsize = SIZE_OF_HEAD + sizeof(OpNode) + num * sizeof(Node *);
    if((p = malloc(nsize)) == NULL) {
        yyerror("out of memory @ opr.\n");
    }
    p->type = TYPE_OP;
    p->op.name = name;
    p->op.num = num;
    va_start(ap, num);
    int i = 0;
    for(i = 0; i < num; ++i) {
        p->op.node[i] = va_arg(ap, Node *);
    }
    va_end(ap);
    p->op.node[num] = NULL;     // set the last node ptr as NULL.
    return p;
}

/**
 * calculate the value of the node in syntax tree.
 * this is the core method to eval the syntax tree.
 */
int execNode(Node *p)
{
    if(!p) { return 0; }
    switch (p->type) {
    case TYPE_CONTENT: return p->content;
    case TYPE_INDEX: return memory[p->index];
    case TYPE_OP:
        switch(p->op.name) {
        case WHILE:
            while(execNode(p->op.node[0])) {
                execNode(p->op.node[1]);
            }
            return 0;
        case IF:
            if(execNode(p->op.node[0])) {
                execNode(p->op.node[1]);
            }
            else if(p->op.num > 2) {
                execNode(p->op.node[2]);
            }
            return 0;
        case PRINT:
            printf("%d\n", execNode(p->op.node[0]));
            return 0;
        case ';':
            execNode(p->op.node[0]);
            return execNode(p->op.node[1]);
        case '=':
            return memory[p->op.node[0]->index] = execNode(p->op.node[1]);
        case UMINUS:
            return -execNode(p->op.node[0]);
        case '+':
            return execNode(p->op.node[0]) + execNode(p->op.node[1]);
        case '-':
            return execNode(p->op.node[0]) - execNode(p->op.node[1]);
        case '*':
            return execNode(p->op.node[0]) * execNode(p->op.node[1]);
        case '/':
            return execNode(p->op.node[0]) / execNode(p->op.node[1]);
        case GE:
            return execNode(p->op.node[0]) >= execNode(p->op.node[1]);
        case GT:
            return execNode(p->op.node[0]) > execNode(p->op.node[1]);
        case LE:
            return execNode(p->op.node[0]) <= execNode(p->op.node[1]);
        case LT:
            return execNode(p->op.node[0]) < execNode(p->op.node[1]);
        case AND:
            return execNode(p->op.node[0]) && execNode(p->op.node[1]);
        case OR:
            return execNode(p->op.node[0]) || execNode(p->op.node[1]);
        case NOT:
            return !execNode(p->op.node[0]);
        case EQ:
            return execNode(p->op.node[0]) == execNode(p->op.node[1]);
        case NE:
            return execNode(p->op.node[0]) != execNode(p->op.node[1]);
        }
    }

    return 0;
}

void freeNode(Node *p)
{
    if(!p) { return; }
    if(p->type == TYPE_OP) {
        int i = 0;
        for(i = 0; i < p->op.num; ++i) {
            freeNode(p->op.node[i]); // free child node.
        }
    }
    free(p);
}

void yyerror(char *s)
{
    printf("ERROR: %s\n", s);
}

int main(int argc, char **argv)
{
    yyparse();

    return 0;
}
