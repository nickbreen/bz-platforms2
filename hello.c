#include <stdio.h>
#include <gnu/libc-version.h>

int main() {
   printf("Hello! Compiled with GNU libc %u.%u!\n", __GLIBC__, __GLIBC_MINOR__);
}
