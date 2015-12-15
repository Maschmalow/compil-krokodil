#ifndef DATA_H
#define DATA_H


#include "../lib/libut.h"

#include "types.h"

struct expr_s;
typedef struct expr_s expr_s;

struct var_s;
typedef struct var_s var_s;


struct var_lmap;
typedef struct var_lmap var_lmap;

struct var_lmap {
    var_s* map;
    
    var_lmap* up; 
};

struct expr_s {
  int  reg;
  char* ll_c;
  type_s* type;
};

struct var_s {
  char* s_id;  //key

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
