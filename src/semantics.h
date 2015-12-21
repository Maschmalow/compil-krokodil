#ifndef SEMANTICS_H
#define SEMANTICS_H

void declarator_tab_semantics(var_s** resultp, var_s* arg1, int arg2);
void declarator_func_semantics(var_s** resultp, var_s* arg1, type_f* arg2);
void binary_op_semantics(expr_s** resultp, expr_s* arg1, const char* arg2, expr_s* arg3);
void comparaison_semantics(expr_s** resultp, expr_s* arg1, const char* arg2, expr_s* arg3);
void assignement_semantics(expr_s** resultp, char* arg1, expr_s* arg3);
void assignement_op_semantics(expr_s** resultp, char* arg1, const char* arg2, expr_s* arg3);
void selection_semantics(char** resultp,  expr_s* cond, char* arg1, char* arg2);
void iteration_semantics(char** resultp, expr_s* arg1, expr_s* arg2, expr_s* arg3, char* arg4);
void iteration_do_while_semantics(char** resultp, char* arg1, expr_s* arg2);
void function_definition_semantics(char** resultp, type_p arg1, var_s* arg2, char* arg3);
void identifier_semantics(expr_s** resultp, char* arg1);
void constant_semantics(expr_s** resultp, int n_val, double f_val, type_p t);
void call_semantics(expr_s** resultp, char* arg1, expr_s** arg2);
void conversion_semantics(expr_s** resultp, expr_s* arg1, type_s* arg3);
void access_tab_semantics(expr_s** resultp, char* arg1, expr_s* arg2);
void incr_decr_semantics(expr_s** resultp, char* arg1, char* arg2);







#endif
