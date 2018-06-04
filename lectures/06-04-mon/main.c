#include <stdio.h>
#include <stdlib.h>

union snake_val {
  int as_int;
  union snake_val* as_ptr;
};

extern void print_error_and_exit()
  asm("print_error_and_exit");

extern union snake_val our_code_starts_here()
  asm("our_code_starts_here");

void print_error_and_exit(int val) {
  printf("Error! %d\n", val);
  exit(1);
}

void print_val(union snake_val val) {
  if(val.as_int & 1) { // It's a primitive value
    printf("%d", (val.as_int - 1) / 2);
  }
  else if (val.as_int == 2) { // It's true
    printf("true");
  }
  else if (val.as_int == 0) { // It's false
    printf("false");
  }
  else { // It's a pair!
    printf("(");
    print_val(val.as_ptr[0]);
    printf(",");
    print_val(val.as_ptr[1]);
    printf(")");
  }
}

int main(int argc, char** argv) {
  int input = 0;

  int* MEMORY = calloc(10000, sizeof(int));

  if(argc > 1) { input = atoi(argv[1]); }
  union snake_val result = our_code_starts_here(input, MEMORY);
  print_val(result);
  printf("\n");
  fflush(stdout);
  return 0;
}

