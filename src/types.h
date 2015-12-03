#ifndef TYPES_H
#define TYPES_H


struct type_s;
struct type_f;
struct type_t;
typedef struct type_s type_s;
typedef struct type_f type_f;
typedef struct type_t type_t;


typedef int type_b;
#define NONE_T ((type_b)[ 0)
#define VOID_T ((type_b) 1)
#define INT_T ((type_b) 2)
#define FLOAT_T ((type_b) 3)
#define CHAR_T ((type_b) 4)

struct type_s {
  type_b base;
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


#endif
