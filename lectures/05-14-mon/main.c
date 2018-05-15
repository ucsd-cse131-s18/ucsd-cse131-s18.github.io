#include <stdio.h>
#include <stdlib.h>
#include <string.h>

union snake_val {
  int as_int;
  union snake_val* as_ptr;
};

extern union snake_val* heap_ptr asm("heap_ptr");
union snake_val* heap_ptr;

extern void print_error_and_exit()
  asm("print_error_and_exit");
extern union snake_val read_line()
  asm("read_line");
extern union snake_val print_val()
  asm("print_val");
extern union snake_val our_code_starts_here()
  asm("our_code_starts_here");

void print_error_and_exit(int val) {
  printf("Error! %d\n", val);
  exit(1);
}

void _print_val(union snake_val val) {
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
    _print_val(val.as_ptr[0]);
    printf(",");
    _print_val(val.as_ptr[1]);
    printf(")");
  }
}

union snake_val print_val(union snake_val val) {
  _print_val(val);
  printf("\n");
  return val;
}

union snake_val read_line(union snake_val* heap_start) {
  char* line = NULL;
  size_t size = 0;
  getline(&line, &size, stdin);
  char* tok = strtok(line, " ");
  union snake_val current = {0};
  if(tok == NULL) { return current; }
  union snake_val prev;
  prev.as_ptr = heap_start;
  prev.as_ptr[0].as_int = atoi(tok) * 2 + 1;
  heap_start += 2;
  union snake_val first = prev;
  tok = strtok(NULL, " ");
  while(tok != NULL) {
    union snake_val link;
    link.as_ptr = heap_start;
    heap_start += 2;
    link.as_ptr[0].as_int = atoi(tok) * 2 + 1;
    prev.as_ptr[1] = link;
    prev = link;
    tok = strtok(NULL, " ");
    //printf("%d\n", atoi(tok));
  }
  prev.as_ptr[1].as_int = 0;
  heap_ptr = heap_start;
  return first;
}

int main(int argc, char** argv) {
  int input = 0;

  union snake_val* MEMORY = calloc(10000, sizeof(int));
  heap_ptr = MEMORY;

  if(argc > 1) { input = atoi(argv[1]); }
  union snake_val result = our_code_starts_here(input, MEMORY);
  print_val(result);
  fflush(stdout);
  return 0;
}

