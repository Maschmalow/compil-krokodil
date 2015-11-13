

int f(int a)
{
  return 1;
}

float azerty(char b)
{
  return -0.4;
}


extern int (*g)(int);

int main()
{
  
  int C[10];
  int B[];
  int A[1000];

  float T2[50];
  char T1[10];

  int (*w)(int);

  
  map(w, C);

  T2 = map(azerty, T1); 

  B = map(g,map(f,A));

}
