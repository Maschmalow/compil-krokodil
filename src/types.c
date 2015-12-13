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

