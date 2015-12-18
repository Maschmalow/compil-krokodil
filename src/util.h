#ifndef UTIL_H
#define UTIL_H

#define ALLOC(x) (x) = malloc(sizeof(*(x)))
#define NALLOC(x, n) (x) = malloc((n)*sizeof(*(x)))
#deinfe REALLOC(x, n) (x) = realloc((x), (n)*sizeof(*(x)))

int new_reg();
char* new_label(const char* prefix);
int add_ll_c(char** ll_c, const char* fmt, ...);
int va_add_ll_c(char** ll_c, const char* fmt, __builtin_va_list va_args);
int add_line(char** ll_c, const char* in_fmt, ...);
        

#endif
