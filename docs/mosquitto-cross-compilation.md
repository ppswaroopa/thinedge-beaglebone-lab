# Mosquitto cross-compilation

This document describes how to cross-compile Eclipse Mosquitto for the
BeagleBone Black.

For the general BeagleBone Black cross-compilation setup, see
[`docs/cross-compilation.md`](cross-compilation.md). For target deployment, see
[`docs/deployment.md`](deployment.md).

## Overview

Mosquitto is built on the host with the same Bootlin ARM toolchain and target
sysroot used by the rest of this project. Optional Mosquitto features are
disabled during early bring-up to keep the dependency graph small.

The minimal build produces:

- `mosquitto`, the MQTT broker executable.
- `libcjson.so.1`, a custom shared library required at runtime.

## Prerequisites

Complete the base toolchain setup first:

1. Download and extract the Bootlin SDK documented in
   [`toolchains/README.md`](../toolchains/README.md).
1. Create the BeagleBone Black sysroot documented in
   [`sysroots/README.md`](../sysroots/README.md).
1. Load the project build environment:

   ```bash
   source scripts/env.sh
   ```

The selected SDK is:

```text
armv7-eabihf--glibc--stable-2018.11-1
```

The compatibility rule is:

```text
toolchain glibc <= target glibc
```

For this project, the toolchain uses glibc 2.27 and the target uses glibc 2.28.

## Build cJSON

Mosquitto uses cJSON for JSON support. Build and install cJSON into
`third_party/install/cjson`.

Clone the source:

```bash
cd third_party/src
git clone https://github.com/DaveGamble/cJSON.git
```

Configure from the repository root:

```bash
mkdir -p third_party/build/cjson
cd third_party/build/cjson

cmake ../../../third_party/src/cJSON \
    -DCMAKE_TOOLCHAIN_FILE=../../../toolchains/bbb-armhf.cmake \
    -DCMAKE_INSTALL_PREFIX=../../../third_party/install/cjson \
    -DENABLE_CJSON_TEST=OFF \
    -DBUILD_SHARED_LIBS=ON \
    -G Ninja
```

Build and install:

```bash
ninja
ninja install
```

Expected install layout:

```text
third_party/install/cjson/
|-- include/
`-- lib/
```

## Build Mosquitto

Clone the source:

```bash
cd third_party/src
git clone https://github.com/eclipse-mosquitto/mosquitto.git
```

Configure from the repository root:

```bash
mkdir -p third_party/build/mosquitto
cd third_party/build/mosquitto

cmake ../../../third_party/src/mosquitto \
    -DCMAKE_TOOLCHAIN_FILE=../../../toolchains/bbb-armhf.cmake \
    -DCMAKE_INSTALL_PREFIX=../../../third_party/install/mosquitto \
    -DCJSON_INCLUDE_DIR=../../../third_party/install/cjson/include \
    -DCJSON_LIBRARY=../../../third_party/install/cjson/lib/libcjson.so \
    -DWITH_TLS=OFF \
    -DWITH_WEBSOCKETS=OFF \
    -DWITH_WEBSOCKETS_BUILTIN=OFF \
    -DWITH_STATIC_LIBRARIES=OFF \
    -DWITH_DOCS=OFF \
    -DWITH_APPS=OFF \
    -DWITH_PLUGINS=OFF \
    -DWITH_PERSISTENCE=OFF \
    -DWITH_CONTROL=OFF \
    -DWITH_TESTS=OFF \
    -G Ninja
```

Build and install:

```bash
ninja
ninja install
```

## Feature selection

Mosquitto includes optional features that add dependencies, including TLS,
websockets, plugins, persistence, applications, documentation, and tests.

The initial embedded build disables those features to:

- Reduce the dependency graph.
- Simplify first boot on the target.
- Keep the runtime footprint small.
- Make missing dependencies obvious and intentional.

Features can be enabled later as the runtime requirements become clearer.

## Verify the build

Check the generated broker architecture:

```bash
file third_party/install/mosquitto/sbin/mosquitto
```

The output should identify an ARM executable.

Check the glibc symbol requirements:

```bash
arm-buildroot-linux-gnueabihf-readelf -a \
    third_party/install/mosquitto/sbin/mosquitto | grep GLIBC
```

The binary must not require a newer glibc version than the BeagleBone Black
provides.

Inspect dynamic dependencies:

```bash
arm-buildroot-linux-gnueabihf-readelf -d \
    third_party/install/mosquitto/sbin/mosquitto
```

Expected runtime dependencies include:

```text
libdl.so.2
libm.so.6
libpthread.so.0
libc.so.6
libcjson.so.1
```

System libraries are provided by the target OS. The custom `libcjson.so.1`
library must be deployed with Mosquitto.

## Install output

The relevant install output is:

```text
third_party/install/
|-- cjson/
|   |-- include/
|   `-- lib/
`-- mosquitto/
    |-- include/
    |-- lib/
    `-- sbin/
        `-- mosquitto
```

Deploy `third_party/install/mosquitto/sbin/mosquitto` and
`third_party/install/cjson/lib/libcjson.so*` using the deployment workflow in
[`docs/deployment.md`](deployment.md).
