%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <search.h>
    #include <string.h>

    #define NB_VAR_MAX 10000
    #include "parse.h"
  

    extern int yylineno;
    int yylex ();
    int yyerror ();
    
    extern int depth;
    
    int new_reg();
    const char* op(char s);
    void binary_op_semantics(expr_s* $$, expr_s* $1, const char* $2, expr_s* $3);
    


      
%}

%token <s_id> IDENTIFIER
%token <f_val> CONSTANTF
%token <n_val> CONSTANTI
%token MAP REDUCE EXTERN
%token INC_OP DEC_OP LE_OP GE_OP EQ_OP NE_OP
%token SUB_ASSIGN MUL_ASSIGN ADD_ASSIGN
%token INT FLOAT VOID CHAR
%token IF ELSE WHILE RETURN FOR DO
%type <t_prim_d> type_name
%type <func_d> parameter_list
%type <type_d> parameter_declaration
%type <var_d> declarator declaration
%type <expr_d> primary_expression postfix_expression argument_expression_list unary_expression unary_operator multiplicative_expression additive_expression comparison_expression expression
%start program

%union {
  char* s_id;
  int n_val;
  float f_val;
  type_s* type_d;
  type_p t_prim_d;
  type_f* func_d;
  var_s* var_d;
  expr_s* expr_d;
}
%%

primary_expression
: IDENTIFIER 
| CONSTANTI 
| CONSTANTF 
| '(' expression ')'
| MAP '(' postfix_expression ',' postfix_expression ')'
| REDUCE '(' postfix_expression ',' postfix_expression ')'
| IDENTIFIER '(' ')'
| IDENTIFIER '(' argument_expression_list ')'
| IDENTIFIER INC_OP
| IDENTIFIER DEC_OP
;

postfix_expression
: primary_expression
| postfix_expression '[' expression ']'
;

argument_expression_list
: expression
| argument_expression_list ',' expression
;

unary_expression
: postfix_expression
| INC_OP unary_expression
| DEC_OP unary_expression
| unary_operator unary_expression
;

unary_operator
: '-'
;



multiplicative_expression
: unary_expression { $$ = $1; $1 = NULL; }
| multiplicative_expression '*' unary_expression { binary_op_semantics($$, $1, op('*'), $3); }
| multiplicative_expression '/' unary_expression { binary_op_semantics($$, $1, op('/'), $3); }
;

additive_expression
: multiplicative_expression { $$ = $1; $1 = NULL; }
| additive_expression '+' multiplicative_expression { binary_op_semantics($$, $1, op('+'), $3); }
| additive_expression '-' multiplicative_expression { binary_op_semantics($$, $1, op('-'), $3); }
;

comparison_expression
: additive_expression
| additive_expression '<' additive_expression
| additive_expression '>' additive_expression
| additive_expression LE_OP additive_expression
| additive_expression GE_OP additive_expression
| additive_expression EQ_OP additive_expression
| additive_expression NE_OP additive_expression
;

expression
: unary_expression assignment_operator comparison_expression
| comparison_expression
;

assignment_operator
: '='
| MUL_ASSIGN
| ADD_ASSIGN
| SUB_ASSIGN
;

declaration
: type_name declarator ';'{ $$->type = $2->type;
                                        type_s* curT = $$->type;
                                        if($$->type->tab != NULL){ 
                                            while( curT->tab != NULL  ) curT = curT->tab->elem; 
                                          curT->prim = $1;
                                        }
                                        else if($$->type->func != NULL) {}
                                        else { $$->type->prim = $1; }
                                        ENTRY e = {$$->s_id, $$}; hsearch(e,ENTER); }
| EXTERN type_name declarator ';'{ $$->type = $3->type;
                                        $$->flags |= VAR_EXTERN; 
                                        type_s* curT = $$->type;
                                        if($$->type->tab != NULL){ 
                                            while( curT->tab != NULL  ) curT = curT->tab->elem; 
                                          curT->prim = $2;
                                        }
                                        else if($$->type->func != NULL) {}
                                        else { $$->type->prim = $2; }
                                        ENTRY e = {$$->s_id, $$}; hsearch(e,ENTER); }
;


type_name
: VOID {$$ = VOID_T; }
| INT {$$ = INT_T; }
| FLOAT {$$ = FLOAT_T; }
| CHAR {$$ = CHAR_T; }
;

declarator
: IDENTIFIER {  $$ = new_empty_var_s(); $$->s_id = $1; }
| '(' declarator ')' { $$ = $2; $2 = NULL; }
| declarator '[' CONSTANTI ']' {$$->type->tab->size = $3; $$->type->tab->elem = $1->type; }
| declarator '[' ']' {$$->type->tab->size = 0; $$->type->tab->elem = $1->type; }
| declarator '(' parameter_list ')' {$$ = new_empty_var_s(); $$->type->func = $3; }
| declarator '(' ')' {$$ = new_empty_var_s(); $$->type->func = malloc(sizeof(*$$->type->func)); $$->type->func->nb_param =0; $$->type->func->params = NULL; $$->s_id = strdup($1->s_id); free_var_s($1); }
;

parameter_list
: parameter_declaration {$$->nb_param = 1;  $$->params[0] = $1;}
| parameter_list ',' parameter_declaration {$$->nb_param = $1->nb_param+1; $$->params = $1->params; $$->params[$1->nb_param] = $3;}
;

parameter_declaration
: type_name declarator {$$ = $2->type;}
;

statement
: compound_statement
| expression_statement
| selection_statement
| iteration_statement
| jump_statement
;

compound_statement
: '{' '}'
| '{' statement_list '}'
| '{' declaration_list statement_list '}'
;

declaration_list
: declaration
| declaration_list declaration
;

statement_list
: statement
| statement_list statement
;

expression_statement
: ';'
| expression ';'
;

selection_statement
: IF '(' expression ')' statement
| IF '(' expression ')' statement ELSE statement
| FOR '(' expression_statement expression_statement expression ')' statement
;

iteration_statement
: WHILE '(' expression ')' statement
| DO statement WHILE '(' expression ')'
;

jump_statement
: RETURN ';'
| RETURN expression ';'
;

program
: external_declaration
| program external_declaration
;

external_declaration
: function_definition
| declaration
;

function_definition
: type_name declarator compound_statement
;

%%
#include <stdio.h>
#include <string.h>

extern char yytext[];
extern int column;
extern int yylineno;
extern FILE *yyin;

char *file_name = NULL;

int yyerror (char *s) {
    fflush (stdout);
    fprintf (stderr, "%s:%d:%d: %s\n", file_name, yylineno, column, s);
    return 0;
}

const char* op(char s){
  if(s == '/') return "div";
  if(s == '*') return "mul";
  if(s == '-') return "sub";
  return  "add";
}

void binary_op_semantics(expr_s* $$, expr_s* $1, const char* $2, expr_s* $3)
 {
	$$ = new_empty_expr_s();
	$$->reg = new_reg(/* id bloc, depth? */);
	
	$$->type->prim = CHAR_T;
	if($1->type->prim == INT_T || $3->type->prim == INT_T || *$2 == 'm') $$->type->prim = INT_T;
	if($1->type->prim == FLOAT_T || $3->type->prim == FLOAT_T || *$2 == 'd') $$->type->prim = FLOAT_T;

	char op_type[2] = {0};
	if($$->type->prim == FLOAT_T) { 
		op_type[0] = 'f'; 
	}
	
	char* tmp = ll_type($$->type);
	asprintf(&($$->ll_c),"%s%s%%%d = %s%s %s %%%d, %%%d\n", $1->ll_c, $3->ll_c, $$->reg, op_type, $2, tmp, $1->reg, $3->reg);
	free(tmp);
	free_expr_s($1);
	free_expr_s($3);
	
}
 
char* ll_type(type_s* t) {
	char* ret;
	if(IS_PRIMARY(t))
	{
		if(t->prim == VOID_T)  return strdup("void");
		if(t->prim == CHAR_T)  return strdup("int8");
		if(t->prim == INT_T)   return strdup("int32");
		if(t->prim == FLOAT_T) return strdup("flaot");
	}

	if(IS_TAB(t)) {
		char* tmp = ll_type(t->tab->elem);
		asprintf(&ret, "[%d x %s]", t->tab->size, tmp);
		free(tmp);
	}

	if(IS_FUNC(t))
	{
		int size;
		char* tmp = ll_type(t->func->ret);
		asprintf(&ret, "%s (", tmp);
		free(tmp); 
		size = strlen(ret) +1;
		for(int i=0; i< t->func->nb_param; i++) 
		{
			tmp = ll_type(t->func->params[i]);
			size += strlen(tmp) +2;
			ret = realloc(ret, size);
			strcat(ret, tmp);
			if(i != t->func->nb_param-1)
				strcat(ret, ", ");
			free(tmp);
		}
		ret = realloc(ret, size +2);
		strcat(ret, " )");
	}
	return ret;
}

int new_reg() //a faire 
{
	static int curReg =0;
	curReg++;
	return curReg;
}
	

int main (int argc, char *argv[]) {
    FILE *input = NULL;
    if (argc==2) {
	input = fopen (argv[1], "r");
	file_name = strdup (argv[1]);
	if (input) {
	    yyin = input;
	}
	else {
	  fprintf (stderr, "%s: Could not open %s\n", *argv, argv[1]);
	    return 1;
	}
    }
    else {
	fprintf (stderr, "%s: error: no input file\n", *argv);
	return 1;
    }
    if(!hcreate(NB_VAR_MAX)) {
        perror("hcreate");
       return 1;
    }
    yyparse ();
    free (file_name);
    return 0;
}

var_s* new_empty_var_s()
{
	type_s* ret = malloc(sizeof(*ret));
	memset(ret, 0, sizeof(*ret));
	ret->type = new_empty_type_s();
	return ret;
}

expr_s* new_empty_expr_s()
{
	expr_s* ret = malloc(sizeof(*ret));
	memset(ret, 0, sizeof(*ret));
	ret->type = new_empty_type_s();
	return ret;
}

type_s* new_empty_type_s()
{
	type_s* ret = malloc(sizeof(*ret));
	memset(ret, 0, sizeof(*ret));
	return ret;	
}

void free_type_s(type_s* t)
{
	if(IS_TAB(t)) free_type_t(t->tab);
	if(IS_FUNC(t)) free_type_f(t->func);
	free(t);	
}

void free_type_t(type_t* t)
{
	free_type_s(t->elem);
	free(t);	
}

void free_type_f(type_f* f)
{
	free_type_s(f->ret);
	for(int i =0; i<f->nb_param; i++)
		free_type_s(f->params[i]);
	if(f->nb_param != 0)
		free(f->params);
	free(f);	
}

void free_expr_s(expr_s* t)
{
	free(t->ll_c);
	free_type_s(t->type);
	free(t);
}

void free_var_s(var_s* f)
{
	free(f->s_id);
	free_type_s(f->type);
	free(f);
}

