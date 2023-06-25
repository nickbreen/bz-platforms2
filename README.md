We want to target platforms with varied GLIBC versions.

    OS             PACKAGE                      GLIBC
    -------------- ---------------------------- -----
    rockylinux:8   glibc-2.28-211.el8.x86_64     2.28
    rockylinux:9   glibc-2.34-60.el9.x86_64      2.34
    centos:6       glibc-2.12-1.212.el6.x86_64   2.12
    centos:7       glibc-2.17-317.el7.x86_64     2.17
    fedora:37      glibc-2.36-9.fc37.x86_64      2.36
    fedora:38      glibc-2.37-4.fc38.x86_64      2.37
    debian:11      libc6 2.31-13+deb11u5         2.31
    debian:12      libc6 2.36-9                  2.36
    ubuntu:kinetic libc6 2.36-0ubuntu4           2.36
    ubuntu:lunar   libc6 2.37-0ubuntu2           2.37

We can use https://github.com/wheybags/glibc_version_header 
to link to lowest-common denominator GLIBC symbols. 

glibc 2.34 has a hard break where you cannot compile
with 2.34 and have it work with older glibc versions
even if you use those version headers. It will always
link `__libc_start_main@GLIBC_2.34`.

So, to target various versions of GLIBC we need to be
cleverer.

The idea is to build `hello.c` for each of these platforms
and automatically build them in a matching container. We
also want one for the host system too, whatever that is.


