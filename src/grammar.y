%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>    
    #include "../lib/libut.h"
    
    #include "parse.h"

    #define NB_VAR_MAX 10000
    #define ALLOC(x) x = malloc(sizeof(*(x)))
    #define ALLOCN(x, n) x = malloc(n*sizeof(*(x)))
    
  

    extern int yylineno;
    int yylex ();
    int yyerror ();
    
    extern int cur_depth;   
    
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
: unary_expression { $$ = $1; }
| multiplicative_expression '*' unary_expression { binary_op_semantics($$, $1, op('*'), $3); }
| multiplicative_expression '/' unary_expression { binary_op_semantics($$, $1, op('/'), $3); }
;

additive_expression
: multiplicative_expression { $$ = $1; }
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
: type_name declarator ';'{ $$ = $2;
                                        $$->depth =cur_depth;
                                        assign_deepest($$->type, $1);
                                        printf("1:%d\n", cur_depth);
                                        }
                                
| EXTERN type_name declarator ';'{ $$ = $3;
                                                    $$->flags |= VAR_EXTERN;
                                                    $$->depth =cur_depth;                                                    
                                                    assign_deepest($$->type, $2);
                                                    printf("2:%d\n", cur_depth);
                                                    }


type_name
: VOID {$$ = VOID_T; }
| INT {$$ = INT_T; }
| FLOAT {$$ = FLOAT_T; }
| CHAR {$$ = CHAR_T; }
;

declarator
: IDENTIFIER {  $$ = new_empty_var_s(); $$->s_id = $1; }
| '(' declarator ')' { $$ = $2;  }
| declarator '[' CONSTANTI ']' {$$ = new_empty_var_s(); ALLOC($$->type->tab); $$->type->tab->size = $3; $$->type->tab->elem = $1->type; }
| declarator '[' ']' {$$ = new_empty_var_s(); ALLOC($$->type->tab); $$->type->tab->size = 0; $$->type->tab->elem = $1->type; }
| declarator '(' parameter_list ')' {$$ = new_empty_var_s(); $$->type->func = $3; }
| declarator '(' ')' {$$ = new_empty_var_s(); ALLOC($$->type->func); $$->type->func->nb_param =0; $$->type->func->params = NULL; $$->s_id = strdup($1->s_id); free_var_s($1); }
;

parameter_list
: parameter_declaration {ALLOC($$); ALLOC($$->params); $$->nb_param = 1;  $$->params[0] = $1;}
| parameter_list ',' parameter_declaration {$$ = $1; $$->params = realloc($$->params, $$->nb_param+1); $$->params[$$->nb_param] = $3; $$->nb_param++;  }
;

parameter_declaration
: type_name declarator {$$ = $2->type;}
;

statement 
: compound_statement {printf("3:%d\n", cur_depth);}
| expression_statement {printf("4:%d\n", cur_depth);}
| selection_statement {printf("5:%d\n", cur_depth);}
| iteration_statement {printf("6:%d\n", cur_depth);}
| jump_statement {printf("7:%d\n", cur_depth);}
;

compound_statement
: '{' '}'  {printf("8:%d\n", cur_depth);}
| '{' statement_list '}' {printf("9:%d\n", cur_depth);}
| '{' declaration_list statement_list '}' {printf("10:%d\n", cur_depth);}
;

declaration_list
: declaration
| declaration_list declaration
;

statement_list
: statement {printf("15:%d\n", cur_depth);}
| statement_list statement {printf("16:%d\n", cur_depth);}
;

expression_statement
: ';'
| expression ';'
;

selection_statement
: IF '(' expression ')' statement {printf("17:%d\n", cur_depth);}
| IF '(' expression ')' statement ELSE statement {printf("18:%d\n", cur_depth);}
| FOR '(' expression_statement expression_statement expression ')' statement {printf("19:%d\n", cur_depth);}
;

iteration_statement
: WHILE '(' expression ')' statement
| DO statement WHILE '(' expression ')'
;

jump_statement
: RETURN ';' {printf("20:%d\n", cur_depth);}
| RETURN expression ';' {printf("21:%d\n", cur_depth);}
;

program
: external_declaration
| program external_declaration {printf("14:%d\n", cur_depth);}
;

external_declaration
: function_definition {printf("11:%d\n", cur_depth);}
| declaration  {printf("12:%d\n", cur_depth);}
;

function_definition
: type_name declarator compound_statement {printf("13:%d\n", cur_depth);}
;

%%
#include <stdio.h>
#include <string.h>

extern char yytext[];
extern int column;
extern int yylineno;
extern FILE *yyin;

char *file_name = NULL;

const char* op(char s){
  if(s == '/') return "div";
  if(s == '*') return "mul";
  if(s == '-') return "sub";
  return  "add";
}

void binary_op_semantics(expr_s* $$, expr_s* $1, const char* $2, expr_s* $3)
 {
     printf("op %s:%d\n", $2, cur_depth); 
     return;
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
 


int new_reg() //a faire 
{
	static int curReg =0;
	curReg++;
	return curReg;
}
	
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
    
    yyparse ();
    free (file_name);
    return 0;
}
