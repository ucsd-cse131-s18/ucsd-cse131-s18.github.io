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
  int result = our_code_starts_here();
  if((result & 1) == 1) {
    printf("%d\n", (result - 1) / 2);
  }
  else if(result == 0x7FFFFFFE) {
    printf("false\n");
  }
  else if(result == 0xFFFFFFFE) {
    printf("true\n");
  }
  else {
    printf("Unknown value: %d\n", result);
  }
  return 0;
}

