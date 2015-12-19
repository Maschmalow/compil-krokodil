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


// the lib used for hashtables is a bit special: to store var_s* in a hashtable, you get a var_s* as a handle (the sae way you have a ite* for a the head of a ite* linked list)
// this struct holds a hashtable of var_s* that represents all the variables declared in a statement.
// it also keeps a link to the hashtable of the parent statement (the one that contain the current one)
// the depth is kept for convenience
struct var_lmap { //lmap, as in linked_maps
    var_s* map;
    
    int depth;
    
    var_lmap* up; 
};
//eventhough the lib takes hashmap as var_s*, in practice we will use var_s** and then dereference them, because the lib actually changes the value of the pointer
//  note: in the code we use var_lmp* and then give the 'map' field to the lib, which is equivalent of using var_s**




//a struct that hold data representing an expression
// each expression is a code, that yields a result stored in a register, which is of type 'type"
struct expr_s {
    int  reg;
    char* ll_c;
    type_s* type;
};

//struct for variables. each var_s* represent a variable that can be store in a hashtable.
// most of the time: a var_s* is built when the semantics for a declaration are read. then, when we have all the needed info, the var is moved to the hashtable for the current statement
// ts_id is the identifier and is used as the key for the hashtable
// addr_reg is the register which holds the variable address
// the flags are currently used only for extern vars
// do I need to explain type?
// hh is need for the hashtable library to work
struct var_s {
    char* s_id;  //key

    int addr_reg;
    int flags;
    type_s* type;

    UT_hash_handle hh; //for uthash
};

#define VAR_NO_FLAG 0
#define VAR_EXTERN 1


void hash_add_l(var_lmap* head, var_s* item);
var_s* hash_find(var_lmap* head, char* key);
void hash_put_all(var_lmap* dst, var_s** src) ; //second arg is var_s** because


void hash_add(var_s** head, var_s* item);
void  clear_var_map(var_s** map);
void  free_var_map(var_s** map);

var_lmap* new_var_lmap(var_s* map, int depth, var_lmap* up); //create a new *initialised* lmap
var_s* new_empty_var_s(); //thoses ones are set to the 'empty' value (which depends on the type)
expr_s* new_empty_expr_s();

//same as for types copies
void copy_expr_s(expr_s* e1, const expr_s* e2);

void  free_var_lmap(var_lmap* v);
void free_expr_s(expr_s* t);
void free_var_s(var_s* f);



#endif
