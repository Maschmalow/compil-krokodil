#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "data.h"

void init_var_lmap(var_s* map, int depth, var_lmap* up)
{
    var_lmap* ret = malloc(sizeof(*ret));
    ret->map = map;
    ret->depth = depth;
    ret->up = up;
 
    return ret;
}

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

void  free_var_lmap(var_lmap* v)
{
    struct var_s *cur_var, *tmp;

    HASH_ITER(hh, v->map, cur_var, tmp) {
        HASH_DEL(v->map, cur_var);  
        free_var_s(cur_var);           
    }
  
    free(v);
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



