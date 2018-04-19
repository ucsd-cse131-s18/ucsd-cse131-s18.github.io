#include <stdio.h>

int main(void) {
  printf("The line with print\n");
  if(42) {
    printf("42 is truthy\n");
  }
  else {
    printf("42 is falsy\n");
  }
}
