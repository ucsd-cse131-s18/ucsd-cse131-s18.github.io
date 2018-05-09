#include <stdlib.h>
#include <stdio.h>

long fact(long n, long sofar) {
  if(n < 1) { return sofar; }
  else {
    return fact(n - 1, sofar * n);
  }
}

int main(int argc, char** argv) {
  long arg = atol(argv[1]);
  long result = fact(arg, 1);
  printf("%ld\n", result);
}
