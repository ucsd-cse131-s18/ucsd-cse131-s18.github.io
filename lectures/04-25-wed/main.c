#include <stdio.h>
#include <stdlib.h>

extern void print_error_and_exit()
  asm("print_error_and_exit");

extern int our_code_starts_here()
  asm("our_code_starts_here");

void print_error_and_exit(int val) {
  printf("Error! %d\n", val);
  exit(1);
}

int main(int argc, char** argv) {
  int input = 0;
  if(argc > 1) { input = atoi(argv[1]); }
  int result = our_code_starts_here(input);
  printf("%d\n", result);
  fflush(stdout);
  return 0;
}

