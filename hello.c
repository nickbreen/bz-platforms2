#include <stdio.h>
#include <gnu/libc-version.h>

int main() {
   printf("Hello! I was compiled against GNU libc %u.%u with GNU C %s at %s %s!\n", __GLIBC__, __GLIBC_MINOR__, __VERSION__, __DATE__, __TIME__);
}
