#ifndef SEMANTICS_H
#define SEMANTICS_H

void declarator_tab_semantics(var_s** resultp, var_s* arg1, int arg2);
void declarator_func_semantics(var_s** resultp, var_s* arg1, type_f* arg2);
void binary_op_semantics(expr_s** resultp, expr_s* arg1, const char* arg2, expr_s* arg3);
void comparaison_semantics(expr_s** resultp, expr_s* arg1, const char* arg2, expr_s* arg3);
void assignement_semantics(expr_s** resultp, expr_s* arg1, expr_s* arg3);
void assignement_op_semantics(expr_s** resultp, expr_s* arg1, const char* arg2, expr_s* arg3);
void selection_semantics(char** resultp,  expr_s* cond, char* arg1, char* arg2);
void iteration_semantics(char** resultp, expr_s* arg1, expr_s* arg2, expr_s* arg3, char* arg4);















#endif