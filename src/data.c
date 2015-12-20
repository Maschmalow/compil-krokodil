#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "util.h"
#include "data.h"


void hash_add_all_param(var_lmap* head, var_s* map)
{
    for(var_s* item = map; item != NULL; item = item->hh_param.next)
        hash_add_l(head, item);
}

void hash_add_l(var_lmap* head, var_s* item)
{
    hash_add(&(head->map), item);
}

var_s* hash_find(var_lmap* head, char* key)
{
    var_s* ret;
    HASH_FIND(hh, head->map, key, strlen(key), ret);
    return ret;
}

void hash_transfer_all(var_lmap* dst, var_s** src) // ! one item can't belong to  two different map
{
      var_s* cur, *tmp;

    HASH_ITER(hh, *src, cur, tmp) {
        HASH_DEL(*src, cur); 
        hash_add_l(dst, cur);
    }
  
} 

void hash_add(var_s** head,  var_s* item)
{
    HASH_ADD_KEYPTR(hh, *head, item->s_id, strlen(item->s_id), item );
}

void hash_add_param(var_s** head,  var_s* item)
{
    HASH_ADD_KEYPTR(hh_param, *head, item->s_id, strlen(item->s_id), item );
}

void  clear_var_map_param(var_s** map)
{
    HASH_CLEAR(hh_param, *map);  
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
    ret->addr_reg = new_reg();
	return ret;
}

expr_s* new_empty_expr_s()
{
	expr_s* ret = malloc(sizeof(*ret));
	memset(ret, 0, sizeof(*ret));
	ret->type = new_empty_type_s();
    ALLOC(ret->ll_c);
    *ret->ll_c = 0;
	return ret;
}

void copy_expr_s(expr_s* e1, const expr_s* e2)
{
    e1->reg = e2->reg;
    e1->ll_c = strdup(e2->ll_c);   
    copy_type_s(e1->type, e2->type);
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



