#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "types.h"



var_s* new_empty_var_s()
{
	var_s* ret = malloc(sizeof(*ret));
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



