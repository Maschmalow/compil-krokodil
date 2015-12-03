#ifndef DATA_H
#define DATA_H


struct data;
typedef struct data data;

struct var_s;
typedef struct var_s var_s;


struct data {
  int  tmp_id;
  char* ll_c;
  type_s* type;
};

struct var_s {
  char* s_id;

  int flags;
  type_s* type;
  int depth;
};
#define VAR_EXTERN 1



#endif
