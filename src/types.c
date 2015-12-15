#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "types.h"


char* ll_type(type_s* t) {
	char* ret;
	if(IS_PRIMARY(t))
	{
		if(t->prim == VOID_T)  return strdup("void");
		if(t->prim == CHAR_T)  return strdup("int8");
		if(t->prim == INT_T)   return strdup("int32");
		if(t->prim == FLOAT_T) return strdup("float");
	}

	if(IS_TAB(t)) {
		char* tmp = ll_type(t->tab->elem);
		asprintf(&ret, "[%d x %s]", t->tab->size, tmp);
		free(tmp);
	}

	if(IS_FUNC(t))
	{
		int size;
		char* tmp = ll_type(t->func->ret);
		asprintf(&ret, "%s (", tmp);
		free(tmp); 
		size = strlen(ret) +1;
		for(int i=0; i< t->func->nb_param; i++) 
		{
			tmp = ll_type(t->func->params[i]);
			size += strlen(tmp) +2;
			ret = realloc(ret, size);
			strcat(ret, tmp);
			if(i != t->func->nb_param-1)
				strcat(ret, ", ");
			free(tmp);
		}
		ret = realloc(ret, size +2);
		strcat(ret, " )");
	}
	return ret;
}

void assign_deepest(type_s* t, type_p p)
{
    if(IS_TAB(t)) assign_deepest(t->tab->elem, p);
    else if(IS_FUNC(t)) assign_deepest(t->func->ret, p);
    else t->prim = p;
}

type_s* new_empty_type_s()
{
	type_s* ret = malloc(sizeof(*ret));
	memset(ret, 0, sizeof(*ret));
	return ret;	
}


void copy_type_s(type_s* t1, const type_s* t2)
{
    t1->prim = t2->prim;
    if(IS_TAB(t2)) {
        ALLOC(t1->tab);
        copy_type_t(t1->tab, t2->tab);
    } else {
        t1->tab = t2->tab;
    }
    if(IS_FUNC(t2)) {
        ALLOC(t1->func);
        copy_type_f(t1->func, t2->func);
    } else {
        t1->func = t2->func;
    }
}

void copy_type_t(type_s* t1, const type_s* t2)
{
    t1->size = t2->size;
    ALLOC(t1->elem);
    copy_type_s(t1->elem, t2->elem);
}

void copy_type_f(type_s* f1, const type_s* f2)
{
    t1->nb_param = t2->nb_param;
    if(t2->params != NULL) {
        NALLOC(t1->params, t2->nb_param);
        for(int i = 0; i < t2->nb_param-1; i++) {
            ALLOC(t1->params[i]);
            copy_type_s(t1->params[i], t2->params[i]);
        }
        
    }
}

void free_type_s(type_s* t)
{
	if(IS_TAB(t)) free_type_t(t->tab);
	if(IS_FUNC(t)) free_type_f(t->func);
	free(t);	
}

void free_type_t(type_t* t)
{
	free_type_s(t->elem);
	free(t);	
}

void free_type_f(type_f* f)
{
	free_type_s(f->ret);
	for(int i =0; i<f->nb_param; i++)
		free_type_s(f->params[i]);
	if(f->nb_param != 0)
		free(f->params);
	free(f);	
}

