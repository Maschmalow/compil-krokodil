#ifndef PARSE_H
#define PARSE_H


struct data;
typedef struct data data;

struct var_s;
typedef struct var_s var_s;

union type_s;
struct type_f;
struct type_t;
typedef union type_s type_s;
typedef struct type_f type_f;
typedef struct type_t type_t;

struct data {
  int  ret_name;
  char* llvm_code;
  type_s* type;
};

struct var_s {
  char* s_id;
  int tmp_id;

  char* code;
  type_s* type;
  int depth;
  
  
};

typedef int type_b;
#define VOID_T ((type_b) 0)
#define INT_T ((type_b) 1)
#define FLOAT_T ((type_b) 2)
#define CHAR_T ((type_b) 3)

union type_s {
  type_b base;
  type_t* tab;
  type_f* func;
};


struct type_t {
  type_s* base;
  int size;
};

struct type_f {
  type_s* ret;
  type_s** params;
  int nb_param;
};


#endif
