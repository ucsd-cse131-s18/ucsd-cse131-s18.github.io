#include <stdio.h>

extern int our_code_starts_here() asm("our_code_starts_here");

int main(int argc, char** argv) {
  int result = our_code_starts_here();
  printf("%d\n", result);
  return 0;
}

