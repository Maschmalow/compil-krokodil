#ifndef DATA_H
#define DATA_H

#include "types.h"

struct expr_s;
typedef struct expr_s expr_s;

struct var_s;
typedef struct var_s var_s;


struct var_map;
typedef struct var_map var_map;
typedef var_map* var_map_list; 

struct var_map {
    var_s* map;
    
    var_map* next; //for utlist
};

struct expr_s {
  int  reg;
  char* ll_c;
  type_s* type;
};

struct var_s {
  char* s_id;

  int flags;
  type_s* type;
  int depth;
  
  UT_hash_handle hh; //for uthash
};

#define NO_FLAG 0
#define VAR_EXTERN 1

expr_s* new_empty_expr_s();
var_s* new_empty_var_s();

void free_expr_s(expr_s* t);
void free_var_s(var_s* f);

#endif
