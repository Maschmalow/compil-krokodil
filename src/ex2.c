int main() {
  int A[1000];
  int i;
  int x;
  int tmp;
  x=0;
  do 
    x++;
  while( x <= 15 );
  for (i=0; i<1000; i++) {
  tmp = A[i];
    tmp=i;
  }
  for (i=0; i<1000; i++) {
    x+=A[i]*A[i];
  }
  return x;
}
