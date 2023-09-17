[![Bazel CI](https://github.com/nickbreen/bz-platforms2/actions/workflows/bazel.yml/badge.svg)](https://github.com/nickbreen/bz-platforms2/actions/workflows/bazel.yml)

Assumptions: you have `bazelisk` on your path as `bazel` and a recent `docker`.

Emulate remote builds with the experimental docker strategy:

    ( cd executors; docker buildx bake )
    bazel test --config docker //:platform-{hello,tar,deb,rpm}-test-suite

Start a local instance of BuildBuddy with remote execution enabled and your API
Key configured in `~/.bazelrc` 
as `build:remote --remote_header=x-buildbuddy-api-key=[REDACTED]`:
    
    docker compose up -d
    bazel test --config remote //:platform-{hello,tar,deb,rpm}-test-suite

Use BuildBuddy Cloud and your API Key configured in `~/.bazelrc` 
as `build:bb --remote_header=x-buildbuddy-api-key=[REDACTED]`: 

    bazel test --config bb //:platform-{hello,tar,deb,rpm}-test-suite

Bazel will cache the outputs and results, so you'll need to invalidate them if 
you want to run these builds/tests repeatedly.

`.bazelrc` configures an environment variable `FUDGE` that can be set to a new
value to invalidate all build outputs and test results. E.g.

    export FUDGE="$(date)"

---

We want to target various platforms:

    OS             Family  PKG GLIBC GCC                  
    -------------- ------ ---- ----- -------
    centos:6       redhat  RPM  2.12   4.4.7  
    centos:7       redhat  RPM  2.17   4.8.5    
    debian:11      debian  DEB  2.31  10.2.1        
    debian:12      debian  DEB  2.36  12.2.0                 
    fedora:37      redhat  RPM  2.36  12.3.1     
    fedora:38      redhat  RPM  2.37  13.2.1     
    rockylinux:8   redhat  RPM  2.28   8.5.0    
    rockylinux:9   redhat  RPM  2.34  11.3.1     
    ubuntu:focal   debian  DEB  2.31   9.4.0          
    ubuntu:jammy   debian  DEB  2.35  11.4.0          

We could use https://github.com/wheybags/glibc_version_header
to link to lowest-common denominator GLIBC symbols. But, glibc 2.34 has a
hard break where you cannot compile with 2.34 and have it work with older
glibc versions even if you use those version headers. It will always
link `__libc_start_main@GLIBC_2.34`.

We could reduce the compilations down to GNU libc 2.12 and 2.34 as the two
lowest common version and then package; this assumes that GNU libc is the only
compilation dependency with some version issue. Consider GCC, or adding OpenSSL too...

So, we sort of have a sparse matrix of:

GLIBC versions:
- 2.12
- 2.17
- 2.28
- 2.31
- 2.34 *** backwards-incompatible change: `__libc_start_main@GLIBC_2.34`!
- 2.36
- 2.37

GCC versions:
- 4.4.7
- 4.8.5
- 8.5.0
- 9.4.0
- 10.2.1
- 11.3.1
- 11.4.0
- 12.2.0
- 12.3.1
- 13.2.1

Packaging Type & OS Family:
- RPM & RedHat-likes
- DEB & Debian-likes
- TGZ

RPM version:
- 4.8.0
- 4.11.3
- 4.14.3
- 4.16.1.3
- 4.18.1

Python version:
- 3.4.10
- 3.6.8
- 3.6.8
- 3.8.10
- 3.9.16
- 3.9.2
- 3.10.12
- 3.11.2
- 3.11.4
- 3.11.5

So, to target various combinations of these tools' versions we need to be clever-er.

The idea will be to build `hello.c` for each of these platforms and
"automatically" build it in a matching container. The extra nice part of this
is that the host platform is now entirely irrelevant.

---

What next?

- We might also want one for the host system too, whatever that is.
- Musl libc and Alpine!

---

Problems...

1. Failures on Ubuntu 23.04/lunar with docker provided by Ubuntu's docker.io package. 

       bazel test --config docker //:platform-{hello,tar,deb,rpm}-test-suite --keep_going
   
   >     FAIL: //:platform-rpm-test_0_centos/6 (see /home/nick/.cache/bazel/_bazel_nick/536d4a2f7bb7c864cad311a4771d7d40/execroot/_main/bazel-out/k8-fastbuild-ST-8ca70333f868/testlogs/platform-rpm-test_0_centos/6/test.log)
   >     INFO: From Testing //:platform-rpm-test_0_centos/6:
   >     ==================== Test output for //:platform-rpm-test_0_centos/6:
   >     + exec platform-rpm-test ./hello-0-0.x86_64.rpm ./hello.rpm
   >     + sudo rpm --install ./hello-0-0.x86_64.rpm
   >     sudo: /etc/sudo.conf is owned by uid 65534, should be 0
   >     sudo: /bin/sudo must be owned by uid 0 and have the setuid bit set
   >     ================================================================================

   and similar for all DEB and RPM tests.

2. Excluding `exec_platforms` from `//:tars` theoretically means it should 
   declare that it is executable on the host: that seems to propagate to being
   instructions to compile `//:hello` for the host too.

---

References:

- https://bazel.build/extending/config
- https://github.com/duarten/rust-bazel-cross
- https://github.com/wheybags/glibc_version_header
- https://github.com/fmeum/rules_jni
- https://github.com/aherrmann/bazel-transitions-demo
- https://github.com/bazelbuild/examples

