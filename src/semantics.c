#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>

#include "parse.h"
#include "semantics.h"



//declarators are tricky:
// the regular expr	ession is 'IDENTIFIER{ []  |  () }*'
// eg. 'var()[][]'
// the type is read from right to left: var is function the return a tab of tabs (aka 2-dimensional tab)
// but the grammar is declarator -> declarator[]
// which mean that the parser actually read from left to right
// 'declarator[size]' is not a tab with its elements defined by 'declarator', but its something that will, depending on 'declarator':
//  - be a function that return a tab, ; if declarator is a fucntion
//  - be a tab with tabs as elements ; if declarator is a tab ( careful here, the size of the tabs elements is the one in the semantic)
//  - be a tab ^^ ; if declarator is primary
//the point is : the result declarator is the given declarator, with the one built fro the semantics inside
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

//same thing
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

//arithmetics. type conversion are made here
void binary_op_semantics(expr_s** resultp, expr_s* arg1, const char* arg2, expr_s* arg3)
{

	*resultp = new_empty_expr_s();
    expr_s* result = *resultp;
	result->reg = new_reg();

    
    if(arg1->type->prim == FLOAT_T || arg3->type->prim == FLOAT_T ) 
    {
        result->type->prim = FLOAT_T;
        conversion_semantics(&arg1, arg1, result->type);
        conversion_semantics(&arg3, arg3, result->type);
    }
    else if(arg1->type->prim == INT_T || arg3->type->prim == INT_T ) 
    {
        result->type->prim = INT_T;
        conversion_semantics(&arg1, arg1, result->type);
        conversion_semantics(&arg3, arg3, result->type);
    }
    else{
        result->type->prim = CHAR_T;
    }
	

	char op_type[2] = {0};
	if(result->type->prim == FLOAT_T) {
		op_type[0] = 'f';
	}

	char* tmp = ll_type(result->type);
    add_ll_c(&(result->ll_c), "%s%s", arg1->ll_c, arg3->ll_c);
	add_line(&(result->ll_c),"%%r%d = %s%s %s %%r%d, %%r%d", result->reg, op_type, arg2, tmp, arg1->reg, arg3->reg);
    //puts(result->ll_c);
	free(tmp);
	free_expr_s(arg1);
	free_expr_s(arg3);

}

//meh, same.
void comparaison_semantics(expr_s** resultp, expr_s* arg1, const char* arg2, expr_s* arg3)
{

	*resultp = new_empty_expr_s();
    expr_s* result = *resultp;
	result->reg = new_reg();

	result->type->prim = INT_T;

    char op_type;
    char cond_type[2] = {0};
	if(arg1->type->prim == FLOAT_T || arg3->type->prim == FLOAT_T )  {
        op_type = 'f';
        cond_type[0] = 'o';
        
        if(arg1->type->prim == FLOAT_T)
            conversion_semantics(&arg3, arg3, arg1->type);
        else
            conversion_semantics(&arg1, arg1, arg3->type);
    } else {
        op_type = 'i';
        if( arg2[0] != 'e' && arg2[0] != 'n')
            cond_type[0] = 's';
        
        if(arg1->type->prim == INT_T)
            conversion_semantics(&arg3, arg3, arg1->type);
        if(arg3->type->prim == INT_T)
            conversion_semantics(&arg1, arg1, arg3->type);
    }

	char* tmp = ll_type(result->type);
    add_ll_c(&(result->ll_c), "%s%s", arg1->ll_c, arg3->ll_c);
	add_line(&(result->ll_c),"%%r%d = %ccmp %s%s %s %%r%d, %%r%d", result->reg, op_type, cond_type, arg2, tmp, arg1->reg, arg3->reg);
    //puts(result->ll_c);
	free(tmp);
	free_expr_s(arg1);
	free_expr_s(arg3);

}

void conversion_semantics(expr_s** resultp, expr_s* arg1, type_s* arg3)
{
    if(equal_type_s(arg1->type, arg3))
    {
        *resultp = arg1;
        return;
    }


	*resultp = new_empty_expr_s();
    expr_s* result = *resultp;
	result->reg = new_reg();
    copy_type_s(result->type, arg3);

    char* op = NULL;
    if( arg1->type->prim == CHAR_T || arg1->type->prim == INT_T) op = "sitofp";
    if( arg1->type->prim == FLOAT_T ) op = "fptosi";


	char* out_type = ll_type(result->type);
    char* in_type = ll_type(arg1->type);
    add_ll_c(&(result->ll_c), "%s", arg1->ll_c);
	add_line(&(result->ll_c),"%%r%d = %s %s %%r%d to %s", result->reg, op, in_type, arg1->reg, out_type);

	free(out_type); free(in_type);
	free_expr_s(arg1); 
}

void function_definition_semantics(char** resultp, type_p arg1, var_s* arg2, char* arg3)
{
    *resultp = NULL;
    assign_deepest(arg2->type, arg1);
    hash_add_l(cur_vars, arg2);
    type_f* f = arg2->type->func;


    int* param_regs = NULL;
    if(f->nb_param != 0)  NALLOC(param_regs, f->nb_param);
    char* def = NULL;
    char* ret_type = ll_type(f->ret);
    add_ll_c(&def,  "%s @%s(", ret_type, arg2->s_id);
    free(ret_type);

    for(int i=0; i< f->nb_param; i++) {
        char* param_type = ll_type(f->params[i]);
        param_regs[i] = new_reg();
        add_ll_c(&def, "%s %%r%d", param_type, param_regs[i]);
        if(i != f->nb_param-1)
            add_ll_c(&def, ", ");

        free(param_type);
    }
    add_ll_c(&def, ")");

    add_line(resultp, "define %s {", def);
    var_s* cur_param = *cur_func_params;
    for(int i=0; i< f->nb_param; i++) {

        char* param_type = ll_type(f->params[i]);
        add_line(resultp, "  %%r%d = alloca %s  ;%s", cur_param->addr_reg, param_type, cur_param->s_id);
        add_line(resultp, "  store %s %%r%d, %s* %%r%d", param_type, param_regs[i], param_type, cur_param->addr_reg);

        cur_param = cur_param->hh_param.next;
        free(param_type);
    }
    add_ll_c(resultp, "%s", arg3);
    add_line(resultp, "}\n\n" );

    free_var_map_param(cur_func_params); free(arg3); free(param_regs); free(def);
}

void identifier_semantics(expr_s** resultp, char* arg1)
{
    *resultp = new_empty_expr_s();
    expr_s* result = *resultp;
    result->reg = new_reg();
    var_s* var;
    for(var_lmap* cur = cur_vars; (var = hash_find(cur, arg1))  == NULL; cur = cur->up);
    copy_type_s(result->type,  var->type);

    char* var_type = ll_type(result->type);
    add_line(&(result->ll_c), "%%r%d = load %s, %s* %%r%d  ;%s", result->reg, var_type, var_type, var->addr_reg, arg1);
    free(var_type); free(arg1);
}

void constant_semantics(expr_s** resultp, int n_val, double f_val, type_p t)
{
    *resultp = new_empty_expr_s();
    expr_s* result = *resultp;
    result->reg = new_reg();
    result->type->prim = t;
    char* e_type = ll_type(result->type);

    if(t == FLOAT_T) {
        add_line(&(result->ll_c), "%%r%d = fadd %s 0, %016lx", result->reg, e_type, *((long int *)&f_val));
	}
    if(t == INT_T || t == CHAR_T)
        add_line(&(result->ll_c), "%%r%d = add %s 0, %d", result->reg, e_type, n_val);

    free(e_type);
}


void call_semantics(expr_s** resultp, char* arg1, expr_s** arg2)
{
    *resultp = new_empty_expr_s();
    expr_s* result = *resultp;
    var_s* var;
    for(var_lmap* cur = cur_vars; (var = hash_find(cur, arg1))  == NULL; cur = cur->up);
    copy_type_s(result->type,  var->type->func->ret);


    char* params = NULL;
    for(int i=0; arg2[i] != NULL; i++) {
        char* param_type = ll_type(arg2[i]->type);
        add_ll_c(&(result->ll_c), "%s", arg2[i]->ll_c);
        conversion_semantics(arg2 + i, arg2[i], var->type->func->params[i]);
        add_ll_c(&params, "%s %%r%d", param_type, arg2[i]->reg);
        if(arg2[i+1] != NULL)
            add_ll_c(&params, ", ");
        free(param_type);
    }



    char* e_type = ll_type(result->type);
    if(result->type->prim != VOID_T) {
        add_line(&(result->ll_c), "%%r%d = call %s @%s(%s)", result->reg, e_type, var->s_id, params);
    } else {
        add_line(&(result->ll_c), "call %s @%s(%s)", e_type, var->s_id, params);
    }

    for(int i=0; arg2[i] != NULL; i++)  free_expr_s(arg2[i]);
    free(arg2); free(arg1); free(e_type); free(params);

}

//conditions and loops are mostly jumps and labels, with previous code inbetween
//be careful to conversions to i1 for conditional jumps though
void iteration_semantics(char** resultp, expr_s* arg1, expr_s* arg2, expr_s* arg3, char* arg4)
{
    *resultp = NULL;
    char* cond = new_label("for.cond"); char* body = new_label("for.body"); char* inc = new_label("for.inc"); char* end = new_label("for.end");
    add_ll_c(resultp, "%s", arg1->ll_c);
    add_line(resultp, "br label %%%s\n", cond);

    add_line(resultp, "%s:", cond);
    add_ll_c(resultp, "%s", arg2->ll_c);
    add_line(resultp, "br i1 %%r%d, label %%%s, label %%%s\n", arg2->reg, body, end); // ! convert to i1

    add_line(resultp, "%s:", body);
    add_ll_c(resultp, "%s", arg4);
    add_line(resultp, "br label %%%s\n", inc);

    add_line(resultp, "%s:", body);
    add_ll_c(resultp, "%s", arg3->ll_c);
    add_line(resultp, "br label %%%s\n", cond);

    add_line(resultp, "%s:", end);
    free(cond); free(body); free(inc); free(end);
    free_expr_s(arg1); free_expr_s(arg2); free_expr_s(arg3); free(arg4);
}

//same
void iteration_do_while_semantics(char** resultp, char* arg1, expr_s* arg2)
{
    *resultp = NULL;
    char* cond = new_label("do.cond"); char* body = new_label("do.body"); char* end = new_label("do.end");
    add_line(resultp, "br label %%%s\n", body);

    add_line(resultp, "%s:", body );
    add_ll_c(resultp, "%s", arg1);
    add_line(resultp, "br label %%%s\n", cond);

    add_line(resultp, "%s:", cond);
    add_ll_c(resultp, "%s", arg2->ll_c);
    add_line(resultp, "br i1 %%r%d, label %%%s, label %%%s\n", arg2->reg, body, end); // ! convert to i1

    add_line(resultp, "%s:", end);
    free(cond); free(body);  free(end);
    free(arg1); free_expr_s(arg2);
}

//same
void selection_semantics(char** resultp,  expr_s* cond, char* arg1, char* arg2)
{
    *resultp = NULL;
    char* then = new_label("if.then"); char* _else = new_label("if.else"); char* end = new_label("if.end");

    add_ll_c(resultp, "%s", cond->ll_c);
    add_line(resultp, "br i1 %%r%d, label %%%s, label %%%s\n", cond->reg, then, _else); // ! convert to i1

    add_line(resultp, "%s:", then);
    add_ll_c(resultp, "%s", arg1);
    add_line(resultp, "br label %%%s\n", end);

    add_line(resultp, "%s:", _else );
    add_ll_c(resultp, "%s", arg2);
    add_line(resultp, "br label %%%s\n", end);

    add_line(resultp, "%s:", end);
    free(then); free(_else);  free(end);
    free_expr_s(cond); free(arg1); free(arg2);
}

 //
void assignement_semantics(expr_s** resultp, char* arg1, expr_s* arg3)
{
	*resultp = new_empty_expr_s();
    expr_s* result = *resultp;
	result->reg = arg3->reg;
    var_s* var;
    for(var_lmap* cur = cur_vars; (var = hash_find(cur, arg1))  == NULL; cur = cur->up);
	copy_type_s(result->type, var->type);

    conversion_semantics(&arg3, arg3, var->type);
	char* tmp = ll_type(result->type);
    add_ll_c(&(result->ll_c), "%s", arg3->ll_c);
	add_line(&(result->ll_c),"store %s %%r%d, %s* %%r%d", tmp, arg3->reg, tmp, var->addr_reg);
	free(tmp); free(arg1);
	free_expr_s(arg3);
}

//
void assignement_op_semantics(expr_s** resultp, char* arg1, const char* arg2, expr_s* arg3)
{
        
    expr_s* op_result;
    expr_s* var;
    identifier_semantics(&var, strdup(arg1));
    binary_op_semantics(&op_result,  var, arg2, arg3);
    assignement_semantics(resultp, arg1, op_result);
}

void incr_decr_semantics(expr_s** resultp, char* arg1, char* arg2)
{

    identifier_semantics(resultp, strdup(arg1));
    expr_s* result = *resultp;

    expr_s* e_1;
    constant_semantics(&e_1, 1, 0, INT_T);

    expr_s* incr;
    assignement_op_semantics(&incr, arg1, arg2, e_1);
    free(result->ll_c);
    result->ll_c = strdup(incr->ll_c);
    free_expr_s(incr);
    
}

void access_tab_semantics(expr_s** resultp, char* arg1, expr_s* arg2)
{
     *resultp = new_empty_expr_s();
    expr_s* result = *resultp;
    var_s* var;
    for(var_lmap* cur = cur_vars; (var = hash_find(cur, arg1))  == NULL; cur = cur->up);
    copy_type_s(result->type,  var->type);

    char* var_type = ll_type(result->type);
    //add_line(&(result->ll_c), "%%r%d = load %s** %%1, align 8", result->reg, var_type, var_type, var->addr_reg, arg1);
    add_ll_c(&(result->ll_c), "%s", arg2->ll_c);
    int tmp_reg = new_reg();
    add_line(&(result->ll_c), "%%r%d = getelementptr %s* %%r%d, i64 %%r%d", tmp_reg, var_type, var->addr_reg, arg2->reg);
    add_line(&(result->ll_c), "%%r%d = load %s, %s* %%r%d", result->reg, var_type, var_type, tmp_reg);


    free(var_type); free(arg1); free_expr_s(arg2);
}
