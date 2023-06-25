#include <stdio.h>
#include <gnu/libc-version.h>

int main() {
   printf("Hello, GNU libc %s!", gnu_get_libc_version());
}
