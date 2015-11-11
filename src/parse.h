enum{
  VINT=0,VVOID,VFLOAT,VARRAY
};
typedef struct type_s{
  int base;
  struct type_s *base_array;
  int nb;
} type_t;
