%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>    
    #include <stdarg.h>
    #include "../lib/libut.h"

    #include "parse.h"


    extern int yylineno;
    int yylex ();
    int yyerror ();

	var_s* pending_map = EMPTY_MAP;

    int new_reg();
    char* new_label(const char* prefix);
    void add_line(char** ll_c, const char* in_fmt, ...);
    
    void declarator_tab_semantics(var_s** resultp, var_s* arg1, int arg2);
    void declarator_func_semantics(var_s** resultp, var_s* arg1, type_f* arg2);
    void binary_op_semantics(expr_s** resultp, expr_s* arg1, const char* arg2, expr_s* arg3);
    void comparaison_semantics(expr_s** resultp, expr_s* arg1, const char* arg2, expr_s* arg3);
    void assignement_semantics(expr_s** resultp, expr_s* arg1, expr_s* arg3);
    void assignement_op_semantics(expr_s** resultp, expr_s* arg1, const char* arg2, expr_s* arg3);
    

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
%type <ll_code> declaration program external_declaration statement compound_statement statement_list expression_statement selection_statement iteration_statement jump_statement declaration_list function_definition
%type <expr_d> primary_expression postfix_expression  unary_expression unary_operator multiplicative_expression additive_expression comparison_expression expression
%start program

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
: type_name declarator ';'{ 
                                        assign_deepest($2->type, $1);
                                        hash_add_l(cur_vars, $2);
                                        free_var_map(&pending_map);
                                        
                                        asprintf(&$$, "");
                                        }
                                
| EXTERN type_name declarator ';'{ 
                                                    $3->flags |= VAR_EXTERN;                                      
                                                    assign_deepest($3->type, $2);
                                                    hash_add_l(cur_vars, $3);
                                                    free_var_map(&pending_map);
                                                    
                                                    asprintf(&$$, "");
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
| expression_statement { $$ = $1; }
| selection_statement { $$ = $1; }
| iteration_statement { $$ = $1; }
| jump_statement { $$ = $1; }
;

compound_statement
: '{' '}'  { $$ = strdup("\n"); }
| '{' statement_list '}' { $$ = $2; }
| '{' declaration_list statement_list '}' { asprintf(&$$, "%s%s", $2, $3); free($2); free($3);}
;

declaration_list
: declaration { $$ = $1;}
| declaration_list declaration { asprintf(&$$, "%s%s", $1, $2); free($1); free($2);}
;

statement_list
: statement {printf("15:%d\n", cur_depth);}
| statement_list statement {printf("16:%d\n", cur_depth);}
;

expression_statement
: ';' { $$ = strdup("\n"); }
| expression ';' { $$ = strdup($1->ll_c); free_expr_s($1); }
;

selection_statement
: IF '(' expression ')' statement { asprintf(&$$, "");}
| IF '(' expression ')' statement ELSE statement {asprintf(&$$, ""); }
| FOR '(' expression_statement expression_statement expression ')' statement {asprintf(&$$, ""); }
;

iteration_statement
: WHILE '(' expression ')' statement { char* cond = new_label("while.cond"); char* body = new_label("while.body"); char* end = new_label("while.end");
                                                        add_line(&$$, "br label %%%s\n\n", cond);
                                                        
                                                        add_line(&$$, "%s:\n%s\n", cond, $3->ll_c );
                                                        add_line(&$$, "br i1 %%%d, label %%%s, label %%%s\n\n", $3->reg, body, end); // ! convert to i1
                                                        
                                                        add_line(&$$, "%s:\n%s\n", body, $5);
                                                        add_line(&$$, "br label %%%s\n\n", cond);
                                                        
                                                        add_line(&$$, "%s:", end);
                                                        free(cond); free(body); free(end);
                                                        free_expr_s($3); free($5);} 
| DO statement WHILE '(' expression ')' { asprintf(&$$, ""); }
;

jump_statement
: RETURN ';' { $$ = strdup("ret void\n");}
| RETURN expression ';' {char* e_type = ll_type($2->type); asprintf(&$$, "ret %s %%%d;\n", e_type, $2->reg ); free(e_type);}
;

program
: external_declaration { $$ = $1; }
| program external_declaration { asprintf(&$$, "%s%s", $1, $2); free($1); free($2);}
;

external_declaration
: function_definition { $$ = $1; }
| declaration  { $$ = $1; }
;

function_definition
: type_name declarator compound_statement {
                                                                    assign_deepest($2->type, $1);
                                                                    printf("13:%d\n", cur_depth);
                                                                    hash_add_l(cur_vars, $2);
                                                                    
                                                                    asprintf(&$$, "");
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

void add_line(char** ll_c, const char* in_fmt, ...) 
{
    char* ident = malloc((2*cur_depth+1)*sizeof(*ident));
    memset(ident, ' ', 2*cur_depth+1);
       
    char* fmt;
    char* result;
    asprintf(&fmt, "%s%s", ident, in_fmt);
    
    __builtin_va_list __local_argv;
    __builtin_va_start( __local_argv, in_fmt );
    vasprintf( &result, fmt, __local_argv );
    __builtin_va_end( __local_argv );
    
    *ll_c = realloc(*ll_c, ((*ll_c == NULL)? 0 : strlen(*ll_c)) + strlen(result) +1);
    strcat(*ll_c, result);
    
    free(ident); free(fmt); free(result);
}


void declarator_tab_semantics(var_s** resultp, var_s* arg1, int arg2)
{
	*resultp = arg1;
	var_s* result = *resultp;
	type_t* inner = new_empty_type_t();
	inner->size = arg2;
	

	if(IS_TAB(result->type))
		result->type->tab->elem->tab = inner;
	if(IS_FUNC(result->type))
		result->type->func->ret->tab = inner;
	else
        result->type->tab = inner;
   
}

void declarator_func_semantics(var_s** resultp, var_s* arg1, type_f* arg2)
{
	*resultp = arg1;
	var_s* result = *resultp;
	type_f* inner = arg2;
	
	if(IS_TAB(result->type))
		result->type->tab->elem->func = inner;
	if(IS_FUNC(result->type))
		result->type->func->ret->func = inner;
	else
        result->type->func = inner;

}


void binary_op_semantics(expr_s** resultp, expr_s* arg1, const char* arg2, expr_s* arg3)
{
	printf("op %s:%d, (%d)\n", arg2, cur_depth, (int) (*resultp)); 

	*resultp = new_empty_expr_s();
    expr_s* result = *resultp;
	result->reg = new_reg();

	
	result->type->prim = CHAR_T;
	if(arg1->type->prim == INT_T || arg3->type->prim == INT_T || *arg2 == 'm') result->type->prim = INT_T;
	if(arg1->type->prim == FLOAT_T || arg3->type->prim == FLOAT_T || *arg2 == 'd') result->type->prim = FLOAT_T;

	char op_type[2] = {0};
	if(result->type->prim == FLOAT_T) { 
		op_type[0] = 'f'; 
	}
	
	char* tmp = ll_type(result->type);
    add_line(&(result->ll_c), arg1->ll_c);
    add_line(&(result->ll_c), arg3->ll_c);
	add_line(&(result->ll_c),"%%%d = %s%s %s %%%d, %%%d\n", result->reg, op_type, arg2, tmp, arg1->reg, arg3->reg);
    puts(result->ll_c);
	free(tmp);
	free_expr_s(arg1);
	free_expr_s(arg3);
	
}

void comparaison_semantics(expr_s** resultp, expr_s* arg1, const char* arg2, expr_s* arg3)
{
	printf("cmp %s:%d\n", arg2, cur_depth); 

	*resultp = new_empty_expr_s();
    expr_s* result = *resultp;
	result->reg = new_reg();
	
	result->type->prim = INT_T;
    
    char op_type;
    char cond_type[2] = {0};
	if(arg1->type->prim == FLOAT_T || arg3->type->prim == FLOAT_T )  {
        op_type = 'f';
        cond_type[0] = 'o';
    } else {
        op_type = 'i';
        if( arg2[0] != 'e' && arg2[0] != 'n')
            cond_type[0] = 's';        
    }
		
	char* tmp = ll_type(result->type);
    add_line(&(result->ll_c), arg1->ll_c);
    add_line(&(result->ll_c), arg3->ll_c);
	add_line(&(result->ll_c),"%%%d = %ccmp %s%s %s %%%d, %%%d\n", result->reg, op_type, cond_type, arg2, tmp, arg1->reg, arg3->reg);
    puts(result->ll_c);
	free(tmp);
	free_expr_s(arg1);
	free_expr_s(arg3);
	
}
 
void assignement_semantics(expr_s** resultp, expr_s* arg1, expr_s* arg3)
{
	printf("ass :%d\n",  cur_depth); 

	*resultp = new_empty_expr_s();
    expr_s* result = *resultp;
	result->reg = arg3->reg;
	
	copy_type_s(result->type, arg1->type);


	char* tmp = ll_type(result->type);
    add_line(&(result->ll_c), arg1->ll_c);
    add_line(&(result->ll_c), arg3->ll_c);
	add_line(&(result->ll_c),"store %s %%%d, %s* %%%d\n", tmp, arg1->reg, tmp, arg3->reg/*addr*/);
    puts(result->ll_c);
	free(tmp);
	free_expr_s(arg1);
	free_expr_s(arg3);
}

void assignement_op_semantics(expr_s** resultp, expr_s* arg1, const char* arg2, expr_s* arg3)
{
    expr_s* inter;
    expr_s* arg1_cp = new_empty_expr_s();
    arg1_cp->reg = arg1->reg;
    arg1_cp->ll_c = strdup("\n");
    copy_type_s(arg1_cp->type, arg1->type);
    
    binary_op_semantics(&inter,  arg1, arg2,  arg3);
    assignement_semantics(resultp, arg1_cp, inter);
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
