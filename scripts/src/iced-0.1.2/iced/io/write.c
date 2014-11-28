#include <stdio.h>
#include <stdlib.h>

void write_counts(char filename [], int* x, int* y, double* counts, int n_lines){
  FILE * fd = fopen(filename, "w");
  unsigned int i = 0;
  while(i != n_lines){
    // if counts is 0, do not write
    if(counts[i] == 0){
      i++;
      continue;
    }
    // The matrix is symmetric, thus only write if x is larger than y
    if(x[i] > y[i]){
      i++;
      continue;
    }
    fprintf(fd, "%d\t%d\t%f\n", x[i], y[i], counts[i]);
    i++;
  }
  fclose(fd);
}
