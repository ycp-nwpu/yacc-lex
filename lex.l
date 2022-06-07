%{
#include <stdlib.h>
#include "node.h"
#include "y.tab.h"

void yyerror(char *);
%}

%%

"/*"([^\*]|(\*)*[^\*/])*(\*)*"*/" {} // multi-line comments.

/* control-flow keywords */
"while" { return WHILE; }
"if" { return IF; }
"else" { return ELSE; }
"print" { return PRINT; }
/* boolean constant value. */
"false" { yylval.ivalue = 0; return INTEGER; }
"true" { yylval.ivalue = 1; return INTEGER; }
[a-z] { yylval.sindex = *yytext - 'a'; return VARIABLE; }
[0-9]+ { yylval.ivalue = atoi(yytext); return INTEGER; }
[\+\-\*\/\(\)\%;{}=] { return *yytext; }
">=" { return GE; }
"<=" { return LE; }
">" { return GT; }
"<" { return LT; }
"==" { return EQ; }
"!=" { return NE; }
"<>" { return NE; }
"&&" { return AND; }
"\|\|" { return OR; }
"!" { return NOT; }
[\t\n ]+ {} /* skip all whitespace, space, \t and \n */
. { printf("unknown symbol, char: %c, ascii: %d\n", *yytext, (int)*yytext); }

%%

int yywarp()
{
    return 1;
}
