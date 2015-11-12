//Affectations fonctions types de base

int main{
    
    int (*f_iii)(int, int);
    float (*f_fci)(char, int);
    void (*f_vcif)(char, int, float);
    void (*f2_vcif)(char, int, float);
    char (*f_c)();


    f_vcif = f2_vcif;

    return 0;

}