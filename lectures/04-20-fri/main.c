#include <stdio.h>

extern int our_code_starts_here()
  asm("our_code_starts_here");

void print_error_and_exit() {
  printf("Error!");
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

// A: A number
// B: Unknown value



    // printf("%d\n", result >> 1);
    // ^ will work, but not everywhere
