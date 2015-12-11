#ifndef TYPES_H
#define TYPES_H

#define IS_PRIMARY(t) (t->prim != NONE_T)
#define IS_TAB(t) (t->tab != NULL)
#define IS_FUNC(t) (t->func != NULL)

struct type_s;
struct type_f;
struct type_t;
typedef struct type_s type_s;
typedef struct type_f type_f;
typedef struct type_t type_t;


typedef int type_p;
#define NONE_T ((type_p) 0)
#define VOID_T ((type_p) 1)
#define INT_T ((type_p) 2)
#define FLOAT_T ((type_p) 3)
#define CHAR_T ((type_p) 4)

struct type_s {
  type_p  prim;
  type_t* tab;
  type_f* func;
};


struct type_t {
  type_s* elem;
  int size;
};

struct type_f {
  type_s* ret;
  type_s** params;
  int nb_param;
};


char* ll_type(type_s* t);

type_s* new_empty_type_s();

void free_type_s(type_s* t);
void free_type_t(type_t* t);
void free_type_f(type_f* f);



#endif