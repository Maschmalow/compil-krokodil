

int main()
{

  void (*)(char[], float) tab1[5]; //un tableau de 5 fonctions qui prennent un tableau de char et un float et qui ne renvoient rien.

    float (*f2)()[];
    
    char (*)(int[10])[50] tab[4]; //un tableau de 4 fonctions qui prennent un tableau de 10 int et qui renvoient un tableau de 50 char.

    float tabf[];
    
    char (*f)(int[10])[50];

    int x[20];

    tabf = f2();

    tab[0] = f;

    tab1[0](tab[2](x));

    return 0;
}
