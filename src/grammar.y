%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>    

    #include "../lib/libut.h"

    #include "parse.h"
    #include "semantics.h"


    extern int yylineno;
    int yylex ();
    int yyerror ();

	var_s* pending_map = EMPTY_MAP;



%}

%token <s_id> IDENTIFIER
%token <f_val> CONSTANTF
%token <n_val> CONSTANTI
%token MAP REDUCE EXTERN
%token INC_OP DEC_OP LE_OP GE_OP EQ_OP NE_OP
%token SUB_ASSIGN MUL_ASSIGN DIV_ASSIGN ADD_ASSIGN
%token INT FLOAT VOID CHAR
%token IF ELSE WHILE RETURN FOR DO
%type <t_prim_d> type_name
%type <func_d> parameter_list
%type <type_d> parameter_declaration
%type <var_d> declarator 
%type <expr_d_list> argument_expression_list
%type <ll_code> declaration program external_declaration statement compound_statement statement_list selection_statement iteration_statement jump_statement declaration_list function_definition
%type <expr_d> primary_expression postfix_expression  unary_expression unary_operator multiplicative_expression additive_expression comparison_expression expression expression_statement
%start start 

%union {
  char* s_id;
  char* ll_code;
  int n_val;
  double f_val;
  type_s* type_d;
  type_p t_prim_d;
  type_f* func_d;
  var_s* var_d;
  expr_s* expr_d;
  expr_s** expr_d_list;
}
%%

primary_expression
: IDENTIFIER { $$ = new_empty_expr_s();
                        var_s* var;
                        for(var_lmap* cur = cur_vars; (var = hash_find(cur, $1))  == NULL; cur = cur->up);
                        copy_type_s($$->type,  var->type); 
                        
                        
                        free($1);}
| CONSTANTI { $$ = new_empty_expr_s(); $$->type->prim = ($1 >= -128 && $1 <= 127)? CHAR_T : INT_T; }
| CONSTANTF { $$ = new_empty_expr_s(); $$->type->prim = FLOAT_T; }
| '(' expression ')' { $$ = $2; }
| MAP '(' postfix_expression ',' postfix_expression ')' 
| REDUCE '(' postfix_expression ',' postfix_expression ')'

| IDENTIFIER '(' ')'  { $$ = new_empty_expr_s();
                                var_s* var;
                                for(var_lmap* cur = cur_vars; (var = hash_find(cur, $1))  == NULL; cur = cur->up);
                                copy_type_s($$->type,  var->type->func->ret); 
                                free($1);}
| IDENTIFIER '(' argument_expression_list ')' { $$ = new_empty_expr_s();
                                                                    var_s* var;
                                                                    for(var_lmap* cur = cur_vars; (var = hash_find(cur, $1))  == NULL; cur = cur->up);
                                                                    copy_type_s($$->type,  var->type->func->ret);
                                                                    
                                                                    while(*$3 != NULL) { free($3); $3++; }
                                                                    free($1);}
                                                                    
| IDENTIFIER INC_OP { $$ = new_empty_expr_s();
                                    var_s* var;
                                    for(var_lmap* cur = cur_vars; (var = hash_find(cur, $1))  == NULL; cur = cur->up);
                                    copy_type_s($$->type,  var->type); 
                                    free($1);}
                                
| IDENTIFIER DEC_OP { $$ = new_empty_expr_s();
                                    var_s* var;
                                    for(var_lmap* cur = cur_vars; (var = hash_find(cur, $1))  == NULL; cur = cur->up);
                                    copy_type_s($$->type,  var->type); 
                                    free($1);}
;

postfix_expression
: primary_expression { $$ = $1; }
| postfix_expression '[' expression ']' {
                                                         $$ = new_empty_expr_s();
                                                         copy_type_s($$->type, $1->type->tab->elem);
                                                         
                                                         free_expr_s($1); free_expr_s($3); }
;

argument_expression_list
: expression {  NALLOC($$, 2); $$[0] = $1; $$[1] = NULL;}
| argument_expression_list ',' expression { $$ = $1; int size = 0; while($$[size] != NULL) size++; $$ = realloc($$, size+1); $$[size-1] = $3; $$[size] = NULL;}
;

unary_expression
: postfix_expression { $$ = $1; }
| INC_OP unary_expression { $$ = $2; }
| DEC_OP unary_expression { $$ = $2; }
| unary_operator unary_expression { $$ = $2; }
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
| additive_expression '<' additive_expression { comparaison_semantics(&$$, $1, "lt", $3); }
| additive_expression '>' additive_expression { comparaison_semantics(&$$, $1, "gt", $3); }
| additive_expression LE_OP additive_expression { comparaison_semantics(&$$, $1, "le", $3); }
| additive_expression GE_OP additive_expression { comparaison_semantics(&$$, $1, "ge", $3); }
| additive_expression EQ_OP additive_expression { comparaison_semantics(&$$, $1, "eq", $3); }
| additive_expression NE_OP additive_expression { comparaison_semantics(&$$, $1, "ne", $3); }
;

expression
: unary_expression '='                 comparison_expression { assignement_semantics(&$$, $1, $3); }
| unary_expression SUB_ASSIGN comparison_expression { assignement_op_semantics(&$$, $1, "sub", $3); }
| unary_expression ADD_ASSIGN comparison_expression { assignement_op_semantics(&$$, $1, "add", $3); }
| unary_expression MUL_ASSIGN  comparison_expression { assignement_op_semantics(&$$, $1, "mul", $3); }
| unary_expression DIV_ASSIGN  comparison_expression { assignement_op_semantics(&$$, $1, "div", $3); }
| comparison_expression { $$ = $1; }
;



declaration //ll_c
: type_name declarator ';'{ $$ = NULL;
                                        assign_deepest($2->type, $1);
                                        hash_add_l(cur_vars, $2);
                                        free_var_map(&pending_map);
                                        
                                        char* tmp = ll_type($2->type);
                                        add_line(&$$, "decl: %s %s (%%%d)", tmp, $2->s_id, $2->addr_reg);
                                        free(tmp);
                                        }
                                
| EXTERN type_name declarator ';'{ $$ = NULL;
                                                    $3->flags |= VAR_EXTERN;                                      
                                                    assign_deepest($3->type, $2);
                                                    hash_add_l(cur_vars, $3);
                                                    free_var_map(&pending_map);
                                                    
                                                    char* tmp = ll_type($3->type);
                                                    add_line(&$$, "decl: extern %s %s (%%%d)", tmp, $3->s_id, $3->addr_reg);
                                                    free(tmp);
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
                                    hash_add(&pending_map, $2);
                                    $$ = new_empty_type_s(); 
                                    copy_type_s($$, $2->type);
                                    }
;

statement 
: compound_statement { $$ = $1; }
| expression_statement { $$ = strdup($1->ll_c); free_expr_s($1); }
| selection_statement { $$ = $1; }
| iteration_statement { $$ = $1; }
| jump_statement { $$ = $1; }
;

compound_statement
: '{' '}'  { $$ = strdup("\n"); }
| '{' statement_list '}' { $$ = $2; }
| '{' declaration_list statement_list '}' { $$ = NULL; add_ll_c(&$$, "%s%s", $2, $3); free($2); free($3);}
;

declaration_list
: declaration { $$ = $1;}
| declaration_list declaration { $$ = NULL; add_ll_c(&$$, "%s%s", $1, $2); free($1); free($2);}
;

statement_list
: statement { $$ = $1; }
| statement_list statement {  $$ = NULL; add_ll_c(&$$, "%s%s", $1, $2); free($1); free($2); }
;

expression_statement
: ';' { $$ = new_empty_expr_s(); $$->type->prim = VOID_T; }
| expression ';' { $$ = $1; }
;

selection_statement
: IF '(' expression ')' statement { selection_semantics(&$$, $3, $5, strdup("\n"));   }
| IF '(' expression ')' statement ELSE statement {  selection_semantics(&$$, $3, $5, $7); }
;


iteration_statement
: WHILE '(' expression ')' statement { $$ = NULL; iteration_semantics(&$$, new_empty_expr_s(), $3, new_empty_expr_s(), $5);} 
| DO statement WHILE '(' expression ')' {    }
| FOR '(' expression_statement expression_statement  expression ')' statement { $$ = NULL; iteration_semantics(&$$, $3, $4, $5, $7);} 
;



jump_statement
: RETURN ';' { $$ = NULL; add_line(&$$, "ret void"); }
| RETURN expression ';' { $$ = NULL; char* e_type = ll_type($2->type);  add_line(&$$, "ret %s %%%d", e_type, $2->reg ); free(e_type);}
;

program
: external_declaration { $$ = $1; }
| program external_declaration { $$ = NULL; add_ll_c(&$$, "%s%s", $1, $2); free($1); free($2); }
;

start
: program { puts($1); free($1);}

external_declaration
: function_definition { $$ = $1; }
| declaration  { $$ = $1; }
;

function_definition
: type_name declarator compound_statement { $$ = NULL;
                                                                    assign_deepest($2->type, $1);
                                                                    printf("13:%d\n", cur_depth);
                                                                    hash_add_l(cur_vars, $2);
                                                                    
                                                                    add_line(&$$, "func_def  %s %s", $2->s_id, $2->type);
                                                                    add_ll_c(&$$, "%s", $3);
                                                                   }
;

%%
#include <stdio.h>
#include <string.h>

extern char yytext[];
extern int column;
extern int yylineno;
extern FILE *yyin;

char *file_name = NULL;




int add_ll_c(char** ll_c, const char* fmt, ...) 
{
    
    __builtin_va_list __local_argv;
    __builtin_va_start( __local_argv, fmt );
    int ret = va_add_ll_c( ll_c, fmt, __local_argv );
    __builtin_va_end( __local_argv );
    
    return ret;
}



int va_add_ll_c(char** ll_c, const char* fmt, __builtin_va_list va_args) 
{
    char* result = NULL;
    
    int ret = vasprintf( &result, fmt, va_args );
    
    if(*ll_c == NULL || **ll_c == 0) 
    {
        *ll_c = result;
    }
    else
    {
        *ll_c = realloc(*ll_c, strlen(*ll_c) + strlen(result) +1);
        strcat(*ll_c, result);
        free(result);
    }
    
    return ret;
}


int add_line(char** ll_c, const char* in_fmt, ...) 
{
    char* ident = malloc((2*cur_depth+1)*sizeof(*ident));
    memset(ident, ' ', 2*cur_depth); ident[2*cur_depth] = 0;
       
    char* fmt = NULL;
    asprintf(&fmt, "%s%s\n", ident, in_fmt);
    
    
    __builtin_va_list __local_argv;
    __builtin_va_start( __local_argv, in_fmt );
    int ret = va_add_ll_c( ll_c, fmt, __local_argv );
    __builtin_va_end( __local_argv );
    

    free(ident); free(fmt); 
    
    return ret;
}

int new_reg() //a faire 
{
    //reg 0 <=> no reg
	static int cur_reg =1;
	return cur_reg++;
}

char* new_label(const char* prefix)
{
    static int cur_count = 0;
    char* ret = NULL;
    asprintf(&ret, "%s%d", prefix, cur_count);
    cur_count++;
    
    return ret;
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
