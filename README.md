[![Bazel CI](https://github.com/nickbreen/bz-platforms2/actions/workflows/bazel.yml/badge.svg)](https://github.com/nickbreen/bz-platforms2/actions/workflows/bazel.yml)

Assuming you have `bazelisk` on your path as `bazel` and a recent `docker`:

    ( cd executors; docker buildx bake )
    bazel build --config docker //:hellos //:tars //:rpms //:debs
    bazel test --config docker //:platform-{hello,tar,deb,rpm}-test-suite
    
    docker compose up -d
    bazel build --config remote //:hellos //:tars //:rpms //:debs
    bazel test --config remote //:platform-{hello,tar,deb,rpm}-test-suite

---

We want to target platforms with varied GLIBC versions.

    OS             Family PKG GLIBC Dependency                  
    -------------- ------ --- ----- ----------------------------
    centos:6       redhat RPM  2.12 glibc-2.12-1.212.el6.x86_64 
    centos:7       redhat RPM  2.17 glibc-2.17-317.el7.x86_64   
    debian:11      debian DEB  2.31 libc6=2.31-13+deb11u5       
    debian:12      debian DEB  2.36 libc6=2.36-9                
    fedora:37      redhat RPM  2.36 glibc-2.36-9.fc37.x86_64    
    fedora:38      redhat RPM  2.37 glibc-2.37-4.fc38.x86_64    
    rockylinux:8   redhat RPM  2.28 glibc-2.28-211.el8.x86_64   
    rockylinux:9   redhat RPM  2.34 glibc-2.34-60.el9.x86_64    
    ubuntu:focal debian DEB  2.36 libc6=2.36-0ubuntu4         
    ubuntu:jammy   debian DEB  2.37 libc6=2.37-0ubuntu2         

We could use https://github.com/wheybags/glibc_version_header
to link to lowest-common denominator GLIBC symbols. But, glibc 2.34 has a
hard break where you cannot compile with 2.34 and have it work with older
glibc versions ven if you use those version headers. It will always
link `__libc_start_main@GLIBC_2.34`.

So, to target various versions of GLIBC we need to be clever-er.

So, we sort of have a sparse matrix of GLIBC versions:

- 2.12
- 2.17
- 2.28
- 2.31
- 2.34 *** hard break `__libc_start_main@GLIBC_2.34`!
- 2.36
- 2.37

By OS/Family/Packaging:

- RPM
- DEB
- TGZ

We could reduce the compilations down to GNU libc 2.12 and 2.34 as the two
lowest common version and then package; this assumes that GNU libc is the only
compilation dependency with some version issue. Consider adding OpenSSL too.
Or python, or what-have-you. So...

The idea will be to build `hello.c` for each of these platforms and
"automatically" build it in a matching container. The extra nice part of this
is that the host platform is now entirely irrelevant. It will generate the 
same outputs on MacOS, Linux, whatever.

---

What next?

- We might also want one for the host system too, whatever that is.
- Musl libc and Alpine!

References:

- https://bazel.build/extending/config
- https://github.com/duarten/rust-bazel-cross
- https://github.com/wheybags/glibc_version_header
- https://github.com/fmeum/rules_jni
- https://github.com/aherrmann/bazel-transitions-demo
- https://github.com/bazelbuild/examples

