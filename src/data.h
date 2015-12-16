#ifndef DATA_H
#define DATA_H


#include "../lib/libut.h"

#include "types.h"

#define EMPTY_MAP ((var_s*) NULL)


struct expr_s;
typedef struct expr_s expr_s;

struct var_s;
typedef struct var_s var_s;


struct var_lmap;
typedef struct var_lmap var_lmap;

struct var_lmap {
    var_s* map;
    
    int depth;
    
    var_lmap* up; 
};

struct expr_s {
    int  reg;
    char* ll_c;
    type_s* type;
};

struct var_s {
    char* s_id;  //key

    int addr_reg;
    int flags;
    type_s* type;

    UT_hash_handle hh; //for uthash
};

#define VAR_NO_FLAG 0
#define VAR_EXTERN 1


void hash_add_l(var_lmap* head, const var_s* item);
var_s* hash_find(var_lmap* head, char* key);
void add_all(var_lmap* dst, const var_s* src) ;


void hash_add(var_s** head, const var_s* item);
void  clear_var_map(var_s** map);
void  free_var_map(var_s** map);

var_lmap* new_var_lmap(var_s* map, int depth, var_lmap* up);
var_s* new_empty_var_s();
expr_s* new_empty_expr_s();

void  free_var_lmap(var_lmap* v);
void free_expr_s(expr_s* t);
void free_var_s(var_s* f);



#endif
