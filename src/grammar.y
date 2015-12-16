%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>    
    #include "../lib/libut.h"

    #include "parse.h"


    extern int yylineno;
    int yylex ();
    int yyerror ();

	var_s* pending_map;

    int new_reg();
    void declarator_tab_semantics(var_s** resultp, var_s* arg1, int arg2);
    void declarator_func_semantics(var_s** resultp, var_s* arg1, type_f* arg2);
    void binary_op_semantics(expr_s** resultp, expr_s* arg1, const char* arg2, expr_s* arg3);
    

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
: IDENTIFIER { $$ = new_empty_expr_s();
				var_s* var;
				for(var_lmap* cur = cur_vars; (var = hash_find(cur, $1)) != NULL; cur = cur->up);
				copy_type_s($$->type,  var->type); }
| CONSTANTI 
| CONSTANTF 
| '(' expression ')' { $$ = $2; }
| MAP '(' postfix_expression ',' postfix_expression ')'
| REDUCE '(' postfix_expression ',' postfix_expression ')'
| IDENTIFIER '(' ')'
| IDENTIFIER '(' argument_expression_list ')'
| IDENTIFIER INC_OP
| IDENTIFIER DEC_OP
;

postfix_expression
: primary_expression { $$ = $1; }
| postfix_expression '[' expression ']'
;

argument_expression_list
: expression
| argument_expression_list ',' expression
;

unary_expression
: postfix_expression { $$ = $1; }
| INC_OP unary_expression
| DEC_OP unary_expression
| unary_operator unary_expression
;

unary_operator
: '-'
;



multiplicative_expression
: unary_expression { $$ = $1; }
| multiplicative_expression '*' unary_expression { binary_op_semantics(&$$, $1, "mul", $3); }
| multiplicative_expression '/' unary_expression { binary_op_semantics(&$$, $1, "div", $3); }
;

additive_expression
: multiplicative_expression { $$ = $1; }
| additive_expression '+' multiplicative_expression { binary_op_semantics(&$$, $1, "add", $3); }
| additive_expression '-' multiplicative_expression { binary_op_semantics(&$$, $1, "sub", $3); }
;

comparison_expression
: additive_expression { $$ = $1; }
| additive_expression '<' additive_expression
| additive_expression '>' additive_expression
| additive_expression LE_OP additive_expression
| additive_expression GE_OP additive_expression
| additive_expression EQ_OP additive_expression
| additive_expression NE_OP additive_expression
;

expression
: unary_expression assignment_operator comparison_expression
| comparison_expression { $$ = $1; }
;

assignment_operator
: '='
| MUL_ASSIGN
| ADD_ASSIGN
| SUB_ASSIGN
;

declaration //var_s*
: type_name declarator ';'{ $$ = $2;
                                        assign_deepest($$->type, $1);
                                        printf("1:%d\n", cur_depth);
                                        hash_add(cur_vars, $$);
                                        free_var_map(pending_map);
                                        }
                                
| EXTERN type_name declarator ';'{ $$ = $3;
                                                    $$->flags |= VAR_EXTERN;                                      
                                                    assign_deepest($$->type, $2);
                                                    printf("2:%d\n", cur_depth);
                                                    hash_add(cur_vars, $$);
                                                    free_var_map(pending_map);
                                                    }


type_name //type_p
: VOID {$$ = VOID_T; }
| INT {$$ = INT_T; }
| FLOAT {$$ = FLOAT_T; }
| CHAR {$$ = CHAR_T; }
;

declarator  //var_s*
: IDENTIFIER {  $$ = new_empty_var_s(); $$->s_id = $1; }
| '(' declarator ')' { $$ = $2;  }
| declarator '[' CONSTANTI ']' { declarator_tab_semantics(&$$, $1, $3); }
| declarator '[' ']' { declarator_tab_semantics(&$$, $1, 0); }
| declarator '(' parameter_list ')' { declarator_func_semantics(&$$, $1, $3); }
| declarator '(' ')' { declarator_func_semantics(&$$, $1, new_empty_type_f()); }
;

parameter_list  //type_f*
: parameter_declaration { $$ = new_empty_type_f(); ALLOC($$->params); $$->nb_param = 1;  $$->params[0] = $1;}
| parameter_list ',' parameter_declaration {$$ = $1; $$->params = realloc($$->params, $$->nb_param+1); $$->params[$$->nb_param] = $3; $$->nb_param++;  }
;

parameter_declaration //type_s*
: type_name declarator {assign_deepest($2->type, $1);                                             
                                    hash_add(pending_map, $2);
                                    $$ = new_empty_type_s(); 
                                    copy_type_s($$, $2->type);
                                    }
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

void declarator_tab_semantics(var_s** resultp, var_s* arg1, int arg2)
{
	*resultp = arg1;
	var_s* result = *resultp;
	type_t* inner = new_empty_type_t();
	inner->size = arg2;
	
	if(IS_PRIMARY(result->type)) 
	{
		result->type->tab = inner;
	}
	if(IS_TAB(result->type))
	{
		result->type->tab->elem->tab = inner;
	}
	if(IS_FUNC(result->type))
	{
		result->type->func->ret->tab = inner;
	}
	
    
}

void declarator_func_semantics(var_s** resultp, var_s* arg1, type_f* arg2)
{
	*resultp = arg1;
	var_s* result = *resultp;
	type_f* inner = arg2;
	
	if(IS_PRIMARY(result->type)) 
	{
		result->type->func = inner;
	}
	if(IS_TAB(result->type))
	{
		result->type->tab->elem->func = inner;
	}
	if(IS_FUNC(result->type))
	{
		result->type->func->ret->func = inner;
	}

}

void binary_op_semantics(expr_s** resultp, expr_s* arg1, const char* arg2, expr_s* arg3)
{
	printf("op %s:%d\n", arg2, cur_depth); 

	*resultp = new_empty_expr_s();
    expr_s* result = *resultp;
	result->reg = new_reg(/* id bloc, depth? */);
	
	result->type->prim = CHAR_T;
	if(arg1->type->prim == INT_T || arg3->type->prim == INT_T || *arg2 == 'm') result->type->prim = INT_T;
	if(arg1->type->prim == FLOAT_T || arg3->type->prim == FLOAT_T || *arg2 == 'd') result->type->prim = FLOAT_T;

	char op_type[2] = {0};
	if(result->type->prim == FLOAT_T) { 
		op_type[0] = 'f'; 
	}
	
	char* tmp = ll_type(result->type);
	asprintf(&(result->ll_c),"%s%s%%%d = %s%s %s %%%d, %%%d\n", arg1->ll_c, arg3->ll_c, result->reg, op_type, arg2, tmp, arg1->reg, arg3->reg);
	free(tmp);
	free_expr_s(arg1);
	free_expr_s(arg3);
	
}
 


int new_reg() //a faire 
{
    //reg 0 <=> no reg
	static int curReg =1;
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
