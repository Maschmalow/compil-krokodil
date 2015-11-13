

int A[1000];

int f(int x) 
{
   return 5;
}

int g(int x,int y) 
{
   return y;
}

int main() {
   int B[];
   int x;
   B = map(f,A); 
   x = reduce(g,B); 
   return x;
}
