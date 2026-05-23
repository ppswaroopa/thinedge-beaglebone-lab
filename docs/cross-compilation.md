# Cross-compilation for BeagleBone Black

This document describes the cross-compilation workflow used to build
applications for the BeagleBone Black from a Linux host machine.

The working setup uses a Bootlin ARMv7 hard-float compiler and a sysroot copied
directly from the BeagleBone Black with `rsync`.

## Overview

The goal is to use an embedded Linux workflow where applications are built on a
host machine and deployed to the target device.

This is similar to workflows used with:

- Yocto SDKs
- Vendor-provided embedded SDKs
- Buildroot toolchains
- Industrial gateway deployment pipelines

Building directly on the target device is useful for quick experiments, but it
does not scale well for repeatable embedded development.

## Architecture

```text
Host machine
    |
    v
Cross toolchain and sysroot
    |
    v
ARM binary
    |
    v
BeagleBone Black
```

## Target device

The target device is a BeagleBone Black running Debian 10.

```bash
uname -m
```

Expected output:

```text
armv7l
```

```bash
cat /etc/os-release
```

Expected output:

```text
Debian GNU/Linux 10 (buster)
```

Check the target glibc version:

```bash
ldd --version
```

Expected output:

```text
GLIBC 2.28
```

## Initial attempt

The first attempt used the Ubuntu-provided ARM cross compiler:

```bash
arm-linux-gnueabihf-g++
```

The binary compiled successfully and `file` reported it as an ARM executable:

```bash
file hello_arm
```

Example output:

```text
ELF 32-bit LSB executable, ARM
```

However, the binary failed at runtime on the BeagleBone Black with errors like:

```text
GLIBC_2.34 not found
GLIBCXX_3.4.32 not found
```

## Root cause

The binary was compiled on a newer host environment than the target runtime
could support.

| Environment | Runtime details |
| --- | --- |
| Host | Ubuntu 24 with newer glibc and libstdc++ |
| Target | Debian 10 with glibc 2.28 |

CPU architecture compatibility is not enough. The target also needs compatible
runtime libraries and ABI versions.

## Working solution

Use a Bootlin compiler with a target sysroot copied from the BeagleBone Black.
The compiler provides the ARM build tools, and the copied sysroot provides the
headers and libraries from the target runtime.

Download the toolchain from
[Bootlin toolchains](https://toolchains.bootlin.com/).

Selected toolchain:

```text
armv7-eabihf--glibc--stable-2018.11-1
```

The Bootlin toolchain provides:

- GCC 7.3
- Buildroot-generated SDK

The target sysroot provides:

- Target headers
- Target libraries
- Target glibc 2.28 runtime files

Compatibility rule for the compiler runtime:

```text
toolchain glibc <= target glibc
```

For this project:

- Toolchain glibc: 2.27
- Target glibc: 2.28

The generated binaries are compatible with the BeagleBone Black runtime.

## Target sysroot

The sysroot is copied directly from the BeagleBone Black with `rsync`.

The sysroot setup is documented in
[`sysroots/README.md`](../sysroots/README.md).

Create or refresh the sysroot from the repository root:

```bash
mkdir -p sysroots/bbb/usr
rsync -avz --delete debian@<BBB_IP>:/lib/ sysroots/bbb/lib/
rsync -avz --delete debian@<BBB_IP>:/usr/include/ sysroots/bbb/usr/include/
rsync -avz --delete debian@<BBB_IP>:/usr/lib/ sysroots/bbb/usr/lib/
```

The project environment expects the sysroot at:

```text
sysroots/bbb/
```

## Toolchain setup

The toolchain setup is documented in
[`toolchains/README.md`](../toolchains/README.md).

After downloading the Bootlin SDK and copying the target sysroot, load the
project environment from the repository root:

```bash
source scripts/env.sh
```

The setup script exports the toolchain root, target sysroot, compiler variables,
and pkg-config paths used by the build workflow.

## Verify the sysroot

Check the highest glibc version available in the copied target sysroot:

```bash
strings sysroots/bbb/lib/arm-linux-gnueabihf/libc.so.6 | grep GLIBC_
```

Expected highest version:

```text
GLIBC_2.28
```

## CMake toolchain file

The project toolchain file is stored at
[`toolchains/bbb-armhf.cmake`](../toolchains/bbb-armhf.cmake).

The file configures:

- Target system name
- Target processor
- C compiler
- C++ compiler
- Sysroot
- CMake package and library lookup behavior

Example configuration:

```cmake
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR arm)

set(CMAKE_C_COMPILER $ENV{CC})
set(CMAKE_CXX_COMPILER $ENV{CXX})

set(CMAKE_SYSROOT $ENV{SYSROOT})

set(CMAKE_FIND_ROOT_PATH
    ${CMAKE_SYSROOT})

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
```

## Build workflow

Load the embedded SDK environment from the repository root:

```bash
source scripts/env.sh
```

Configure the project with the CMake toolchain file:

```bash
cmake ../apps/hello_arm \
    -DCMAKE_TOOLCHAIN_FILE=../toolchains/bbb-armhf.cmake \
    -G Ninja
```

Build the binary:

```bash
ninja
```

Verify the generated binary:

```bash
file hello_arm
```

Inspect runtime requirements:

```bash
readelf -a hello_arm | grep GLIBC
```

## Deployment workflow

Copy the binary to the BeagleBone Black:

```bash
scp hello_arm debian@<BBB_IP>:/home/debian/
```

Run the binary on the target:

```bash
chmod +x hello_arm
./hello_arm
```

## Troubleshooting

### Missing glibc version

If the target reports `GLIBC_x.y not found`, the binary was linked against a
newer runtime than the target provides.

Fix this by using a toolchain with a glibc version that is older than or equal
to the target glibc version.

### Wrong architecture

Use `file` to confirm that the binary targets ARM:

```bash
file hello_arm
```

### Unexpected dynamic dependencies

Use `readelf` to inspect the binary:

```bash
readelf -a hello_arm | grep GLIBC
```

## Lessons learned

- Cross-compilation requires both CPU and runtime compatibility.
- glibc compatibility is critical for embedded Linux targets.
- SDK-based toolchains improve reproducibility and ABI consistency.
- Host build environments and target runtime environments should stay separate.
- Yocto SDKs and vendor SDKs solve this class of problem.
