#include <stdlib.h>
#include <stdio.h>

int main(int argc, char* argv[]) {
    for (int i = 0; i < argc; i++)
        fprintf(stderr, "argv[%i] = <%s>\n", i, argv[i]);
    for (;;) { printf("%c\t", getchar()); }
}
