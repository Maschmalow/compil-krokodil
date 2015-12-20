%{
#include <stdio.h>
#include <string.h>
#include "parse.h"
#include "grammar.tab.h"
void count();
int comment ();
int cur_depth = 0;
var_lmap root = {EMPTY_MAP, 0, NULL};
var_lmap* cur_vars = &root;

%}
D[0-9]
L[a-zA-Z_]
%option yylineno
%%
"/*"		{ comment(); }
"//".*          { count(); }
"float"		{ count(); return(FLOAT); }
"if"		{ count(); return(IF); }
"else"		{ count(); return(ELSE); }
"int"		{ count(); return(INT); }
"char"          { count(); return(CHAR); }
"return"	{ count(); return(RETURN); }
"void"		{ count(); return(VOID); }
"while"		{ count(); return(WHILE); }
"do"		{ count(); return(DO); }
"for"		{ count(); return(FOR); }
"map"           { count(); return(MAP); }
"reduce"        { count(); return(REDUCE); }
"extern"        { count(); return(EXTERN); }
[$]?{L}({L}|{D})*	{ count(); yylval.s_id=strdup(yytext); return(IDENTIFIER); }
{D}+    	{ count(); yylval.n_val=atoi(yytext); return(CONSTANTI); }
{D}+"."{D}*     { count(); yylval.f_val=atof(yytext); return(CONSTANTF); }
"'"({L}|{D})"'" { count(); yylval.c_val=yytext[1]; return(CONSTANTC); }
"+="		{ count(); return(ADD_ASSIGN); }
"-="		{ count(); return(SUB_ASSIGN); }
"*="		{ count(); return(MUL_ASSIGN); }
"/="		{ count(); return(DIV_ASSIGN); }
"++"		{ count(); return(INC_OP); }
"--"		{ count(); return(DEC_OP); }
"<="		{ count(); return(LE_OP); }
">="		{ count(); return(GE_OP); }
"=="		{ count(); return(EQ_OP); }
"!="		{ count(); return(NE_OP); }
";"		{ count(); return(';'); }
"{"      	{ count(); cur_depth++;  var_lmap* down_map = new_var_lmap(EMPTY_MAP, cur_depth, cur_vars); cur_vars = down_map; hash_transfer_all(cur_vars, &pending_vars);  return('{'); }
"}"      	{ count(); cur_depth--; var_lmap* up_map = cur_vars->up; free_var_lmap(cur_vars); cur_vars = up_map; return('}'); }
","		{ count(); return(','); }
"/"		{ count(); return('/'); }
"="		{ count(); return('='); }
"("		{ count(); return('('); }
")"		{ count(); return(')'); }
"["     	{ count(); return('['); }
"]"     	{ count(); return(']'); }
"."		{ count(); return('.'); }
"!"		{ count(); return('!'); }
"-"		{ count(); return('-'); }
"+"		{ count(); return('+'); }
"*"		{ count(); return('*'); }
"<"		{ count(); return('<'); }
">"		{ count(); return('>'); }
[ \t\v\n\f]	{ count(); }
.		{ /* ignore bad characters */ }

%%
int yywrap() {
	return 1;
}
/* This function reads a comment. Comments are not part of the grammar. */
int comment() {
	char c, c1;
loop:
	while ((c = input()) != '*' && c != 0);
	if ((c1 = input()) != '/' && c != 0) {
		unput(c1);
		goto loop;
	}
	return 0;
}

int column = 0;
/* This function counts the number of character, for debugging purposes */
void count() {
	int i;
	for (i = 0; yytext[i] != '\0'; i++) {
		if (yytext[i] == '\n')
			column = 0;
		else if (yytext[i] == '\t')
			column += 8 - (column % 8);
		else
			column++;
	}
}
