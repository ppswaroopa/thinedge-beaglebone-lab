# Toolchain and sysroot setup

This directory contains the CMake toolchain file for building BeagleBone Black
applications from a Linux host machine.

The Bootlin SDK itself is not committed to the repository. Download and extract
it locally. The target sysroot is also not committed; copy it from the
BeagleBone Black with `rsync`.

## Toolchain

This project uses the following Bootlin toolchain:

```text
armv7-eabihf--glibc--stable-2018.11-1
```

Download it from
[Bootlin toolchains](https://toolchains.bootlin.com/).

## Sysroot

The build uses a sysroot copied directly from the BeagleBone Black target.

The sysroot setup is documented in
[`sysroots/README.md`](../sysroots/README.md).

Expected sysroot path:

```text
sysroots/bbb/
```

This keeps local headers and libraries aligned with the target device.

## Compatibility

The selected compiler and target sysroot match the BeagleBone Black runtime used
in this lab.

| Item | Version |
| --- | --- |
| BeagleBone Black glibc | 2.28 |
| Bootlin toolchain glibc | 2.27 |
| Local sysroot | Copied from BeagleBone Black |

The toolchain glibc version must be older than or equal to the target glibc
version. The copied target sysroot keeps headers and target libraries aligned
with the device runtime.

## Directory layout

Extract the downloaded SDK under `toolchains/`.

Expected layout:

```text
toolchains/
|-- README.md
|-- bbb-armhf.cmake
`-- armv7-eabihf--glibc--stable-2018.11-1/
```

The extracted SDK directory is ignored by Git. Only the documentation and CMake
toolchain file are tracked.

## Environment setup

Load the embedded SDK environment before configuring or building applications:

```bash
source scripts/env.sh
```

The script sets:

- `PROJECT_ROOT`
- `TOOLCHAIN_ROOT`
- `SYSROOT`
- `PATH`
- `CC`
- `CXX`
- `PKG_CONFIG_SYSROOT_DIR`
- `PKG_CONFIG_PATH`
- `PKG_CONFIG_LIBDIR`

The `SYSROOT` variable points to `sysroots/bbb`.

## CMake usage

Configure a project with the BeagleBone Black toolchain file:

```bash
cmake ../apps/hello_arm \
    -DCMAKE_TOOLCHAIN_FILE=../toolchains/bbb-armhf.cmake \
    -G Ninja
```

Build with Ninja:

```bash
ninja
```
