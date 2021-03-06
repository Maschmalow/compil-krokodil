#ifndef TYPES_H
#define TYPES_H

#include "util.h"

#define IS_PRIMARY(t) ((t)->prim != NONE_T)
#define IS_TAB(t) ((t)->tab != NULL)
#define IS_FUNC(t) ((t)->func != NULL)
#define IS_EMPTY(t) ( !IS_PRIMARY(t) && !IS_FUNC(t) && IS_TAB(t) ) 

struct type_s;
struct type_f;
struct type_t;
typedef struct type_s type_s;
typedef struct type_f type_f;
typedef struct type_t type_t;


typedef int type_p;
#define NONE_T ((type_p) 0) //special value assigned when type is not primary
#define VOID_T ((type_p) 1)
#define INT_T ((type_p) 2)
#define FLOAT_T ((type_p) 3)
#define CHAR_T ((type_p) 4)

//here, conceptually we would need an union, because a type can be any of thoses three. but as we need to know which field is valid,
//  we set the non used fields to 0 or NULL
struct type_s {
  type_p  prim;
  type_t* tab; //NULL if type is not tab
  type_f* func; //NULL if type is not func
};


struct type_t { //struct that holds tab type
  type_s* elem;
  int size;
};

struct type_f { //struct that holds function type
  type_s* ret;
  type_s** params; //always NULL when no param
  int nb_param;
};
//we make no distinction between function pointers and functions. functions are variables like others, with the distinction that we can call them.


char* ll_type(type_s* t); //allocate a string which contain the llvm representation of a type
 //when building a type (i.e. for a declaration), we know first if its a tab, a function, a function that returns a tab of functions, etc...
 //but we know the primary type of the deepest type at the end
 // for instance, for the function that returns a tab of functions, the deepest primary type is the return type of the functions in the tab returned by the function :)
void assign_deepest(type_s* t, type_p p); //so you get it, it assigns to the deepest type its priary type
char equal_type_s(const type_s* t1, const type_s* t2);

type_s* new_empty_type_s(); //not a type of any kind
type_f* new_empty_type_f(); //no param, empty ret type
type_t* new_empty_type_t(); //size 0, empty elem type

//deep copies. pointer 1 needs to be already allocated, but its content will be overwritten
// typically, t1 is new_empty_X()
void copy_type_s(type_s* t1, const type_s* t2);
void copy_type_t(type_t* t1, const type_t* t2);
void copy_type_f(type_f* f1, const type_f* f2);

void free_type_s(type_s* t);
void free_type_t(type_t* t);
void free_type_f(type_f* f);



#endif
