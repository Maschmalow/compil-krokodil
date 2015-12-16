#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "data.h"


void hash_add(var_lmap* head, const var_s* item)
{
    hash_add(&(head->map), item);
}

void hash_add(var_s** head, const var_s* item)
{
    HASH_ADD_KEYPTR(hh, head, item->s_id, strlen(item->s_id), item );
}

var_s* hash_find(var_lmap* head, char* key)
{
    var_s* ret;
    HASH_FIND(hh, head->map, key, strlen(key), ret);
    return ret;
}

void add_all(var_lmap* dst, const var_s* src) 
{
    for(var_s* cur_var = src; cur_var != NULL; cur_var = cur_var->hh.next) {
        hash_add(dst, cur_var);    
    } 
} 

void  clear_var_map(var_s** map)
{
    HASH_CLEAR(hh, *map);  
}

void  free_var_map(var_s** map)
{
    struct var_s *cur_var, *tmp;

    HASH_ITER(hh, *map, cur_var, tmp) {
        HASH_DEL(*map, cur_var);  
        free_var_s(cur_var);           
    }
}



var_lmap* new_var_lmap(var_s* map, int depth, var_lmap* up)
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
    free_var_map(&(v->map));
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



