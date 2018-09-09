%{
#include <stdio.h>
#include <stdlib.h>
#include <conio.h>
#include "y.tab.h"

FILE *yyin;
int yylval;
%}

%option noyywrap
%option yylineno

DIGITO			[0-9]
LETRA			[a-zA-Z]
CTE				{DIGITO}*(.{DIGITO}+)?
ID				{LETRA}({LETRA}|{DIGITO}|_)*
CADENA			\"({LETRA}|{DIGITO}|!|¡|>|:|<|[ ]|+|@|%|#|&|°|´|^|`|?|¿|~|/|\|-|_|.|;)*\"

%%

"+"				{ return OP_SUMA; }
"-"				{ return OP_RESTA; }
"*"				{ return OP_MULT; }
"/"				{ return OP_DIV; }
"="			    { return ASIG; }
"("				{ return P_A; }
")"				{ return P_C; }

{DIGITO}+		{ yylval = atoi(yytext); return CTE; }
{ID}			{ printf("ID es: %s\n",yytext);return ID;}

"\n"
"\t"
