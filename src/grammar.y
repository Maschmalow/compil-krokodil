%{
    #include <stdio.h>
    #include <search.h>

    #define NB_VAR_MAX 10000
    #include "parse.h"
  
  const char* t_base_names[5] = {NULL, "void", "int32", "float", "int8" } 

    extern int yylineno;
    int yylex ();
    int yyerror ();

    type_t tmp = {NONE_T, NULL, NULL}
    type_t*  EMPTY_TYPE= &tmp;
    extern int depth;
    
    char* ll_type(type_s* t) {
      char* ret;
      if(t->base != NONE_T)
	ret = strdup(t_base_names[t->base]);

      if(t->tab != NULL)
	sprintf(ret, "[ %d x %s ]", t->tab.size, ll_type(t->tab.base));

      if(t->func != NULL)
	{
	  sprintf(ret, "%s (",ll_type(t->func.ret));
	  for(int i=0; i< t->func.nb_param; i++)
	    strcat(ret, ll_type(func->params[i]

	}
	return ret;
    }

      
%}

%token <s_id> IDENTIFIER
%token <f_val> CONSTANTF
%token <n_val> CONSTANTI
%token MAP REDUCE EXTERN
%token INC_OP DEC_OP LE_OP GE_OP EQ_OP NE_OP
%token SUB_ASSIGN MUL_ASSIGN ADD_ASSIGN
%token INT FLOAT VOID CHAR
%token IF ELSE WHILE RETURN FOR DO
%type <t_base_d> type_name
%type <func_d> parameter_list
%type <type_d> parameter_declaration
%type <var_d> declarator
%type <e_data> primary_expression postfix_expression argument_expression_list unary_expression unary_operator multiplicative_expression additive_expression comparison_expression expression
%start program

%union {
  char* s_id;
  int i_val;
  float f_val;
  type_s* type_d;
  type_b t_base_d;
  type_f* func_d;
  var_s* var_d;
  data* e_data;
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
: unary_expression
| multiplicative_expression '*' unary_expression
| multiplicative_expression '/' unary_expression
;

additive_expression
: multiplicative_expression { $$ = $1}
| additive_expression '+' multiplicative_expression {sprintf($$->ll_c,"%s%s%%%d = add %s %%%d, %%%d\n", $1->ll_c, $3->ll_c, $$->type);
| additive_expression '-' multiplicative_expression
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
                                        if($$->type->tab != NULL){ $$->type->tab->elem while( curT->tab != NULL  ) curT = curT->tab->elem;  curT->base = $1;}
                                        else if($$->type->func != NULL) {}
                                        else { $$->type->base = $1; }
                                        ENTRY e = {$2->s_id, $2}; hsearch(e,ENTER)}
| EXTERN type_name declarator ';'{ $3->flags |= VAR_EXTERN; ENTRY e = {$2->s_id, $2}; hsearch(e,ENTER)}
;


type_name
: VOID {$$ = VOID_T;}
| INT {$$ = INT_T; }
| FLOAT {$$ = FLOAT_T;}
| CHAR {$$ = CHAR_T;}
;

declarator
: IDENTIFIER { $$->s_id = $1; $$->type = EMPTY_TYPE}
| '(' declarator ')' {$$ = $2;}
| declarator '[' CONSTANTI ']' {$$->type->tab->size = $3; $$->type->tab->elem = $1->type}
| declarator '[' ']' {$$->type->tab->size = 0; $$->type->tab->elem = $1->type}
| declarator '(' parameter_list ')' {$$->type->func = $3}
| declarator '(' ')' {$$->type->func->nb_param =0; $$->type->func->params =NULL; $$->s_id = $1->s_id}
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



