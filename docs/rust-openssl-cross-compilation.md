# Rust Cross-Compilation + OpenSSL Validation on BeagleBone Black

## Objective

Validate a reproducible embedded Linux cross-compilation workflow for:

* ARMv7 (`armhf`) BeagleBone Black target
* Rust applications
* Native dependency integration (OpenSSL)
* Sysroot-aware builds
* rsync + systemd deployment workflow
* Bootlin external toolchain usage

This work was done before attempting to build and deploy thin-edge.io.

### Target Platform

Target device:

* BeagleBone Black
* Debian userspace
* ARMv7 hard-float (`armhf`)

Verified target information:

```bash
uname -m
# armv7l


dpkg --print-architecture
# armhf


ldd --version
# glibc 2.28
```

OpenSSL version on target:

```bash
openssl version
# OpenSSL 1.1.1d
```

## Toolchain Selection

Selected external toolchain:

Bootlin:

```text
armv7-eabihf--glibc--stable-2018.11-1
```

Important toolchain binaries:

```text
arm-buildroot-linux-gnueabihf-gcc
arm-buildroot-linux-gnueabihf-g++
arm-buildroot-linux-gnueabihf-ar
arm-buildroot-linux-gnueabihf-ld
```

## Initial SDK Environment

A reusable SDK activation script was created:

```text
scripts/env.sh
```

Purpose:

* centralize toolchain setup
* centralize sysroot configuration
* avoid scattered linker/path configuration
* provide reproducible build environment

Core environment variables:

```bash
export PROJECT_ROOT=...
export TOOLCHAIN_ROOT=...
export SYSROOT=...

export PATH="$TOOLCHAIN_ROOT/bin:$PATH"

export CC=arm-buildroot-linux-gnueabihf-gcc
export CXX=arm-buildroot-linux-gnueabihf-g++

export AR=arm-buildroot-linux-gnueabihf-ar
export LD=arm-buildroot-linux-gnueabihf-ld
export STRIP=arm-buildroot-linux-gnueabihf-strip

export CARGO_TARGET_ARMV7_UNKNOWN_LINUX_GNUEABIHF_LINKER=$CC
```

## Rust Toolchain Setup

Installed on HOST only:

```bash
curl https://sh.rustup.rs -sSf | sh
source ~/.cargo/env
```

Installed ARM target:

```bash
rustup target add armv7-unknown-linux-gnueabihf
```

Verified:

```bash
rustc --version
cargo --version
```

## First Rust Validation

Created a minimal Rust application:

```bash
cargo new hello-arm
```

Configured linker via Cargo:

```toml
[target.armv7-unknown-linux-gnueabihf]
linker = "/path/to/arm-buildroot-linux-gnueabihf-gcc"
```

Built successfully:

```bash
cargo build --release --target armv7-unknown-linux-gnueabihf
```

Binary verification:

```bash
file hello-arm
```

Output:

```text
ELF 32-bit LSB pie executable, ARM
```

ABI verification:

```bash
readelf -A hello-arm
```

Important confirmed values:

```text
Tag_CPU_arch: v7
Tag_ABI_VFP_args: VFP registers
```

Meaning:

* ARMv7 build successful
* hard-float ABI correct
* compatible with Debian armhf runtime

Binary executed successfully on target.

## Native Dependency Validation Goal

Before attempting thin-edge.io, the next goal was:

```text
Validate Rust + OpenSSL + cross-linking
```

Reason:

thin-edge.io depends heavily on:

* TLS
* OpenSSL
* MQTT security
* certificates
* native libraries

## OpenSSL Investigation

Confirmed OpenSSL headers existed:

```bash
find sysroots/bbb -name ssl.h
```

Confirmed libraries existed:

```bash
find sysroots/bbb -name "libssl.so*"
find sysroots/bbb -name "libcrypto.so*"
```

Observed:

```text
libssl.so
libcrypto.so
```

## First OpenSSL Failure

Created Rust TLS test application.

Dependency:

```toml
openssl = "0.10"
```

First failure:

```text
Could not find openssl via pkg-config
```

Cause:

The Bootlin sysroot did not contain:

```text
openssl.pc
libssl.pc
```

Even though libraries and headers existed.

Important embedded Linux lesson:

```text
Runtime rootfs != SDK sysroot
```

Many runtime systems omit:

* pkg-config metadata
* development files
* SDK artifacts

## Sysroot Strategy Decision

At this point there were TWO sysroots:

| Sysroot             | Purpose                     |
| ------------------- | --------------------------- |
| Bootlin sysroot     | compiler/runtime SDK        |
| rsynced BBB sysroot | exact target runtime mirror |

Decision:

DO NOT merge them blindly.

Reason:

Mixing:

* libc
* pthread
* linker runtimes
* static archives

from unrelated environments creates:

* ABI issues
* linker instability
* difficult debugging

Instead:

* Bootlin sysroot remained primary SDK
* BBB sysroot used only for missing metadata/headers

## Second OpenSSL Failure

After adding OpenSSL include/library references:

```text
fatal error: openssl/opensslconf.h: No such file or directory
```

Cause:

Debian multiarch include layout.

Important lesson:

Architecture-specific headers existed in:

```text
/usr/include/arm-linux-gnueabihf/
```

not only:

```text
/usr/include/
```

Added:

```bash
export CFLAGS="--sysroot=$SYSROOT -I$BBB_SYSROOT/usr/include/arm-linux-gnueabihf"
export CXXFLAGS="$CFLAGS"
```

## Third Failure - Linker Contamination

Next linker failure:

```text
libpthread.a: relocation ... can not be used when making a shared object
```

Cause:

Debian pkg-config metadata injected:

```text
-L<bbb sysroot>/usr/lib/arm-linux-gnueabihf
```

This caused linker contamination.

The linker accidentally selected:

```text
libpthread.a
```

from Debian sysroot instead of Bootlin runtime.

Important embedded Linux lesson:

```text
Headers can be overlaid carefully.
Libraries should come from ONE coherent runtime set.
```

## Final Solution - Vendored OpenSSL

Instead of fighting:

* pkg-config rewriting
* Debian multiarch behavior
* mixed runtime libraries
* linker precedence

Decision:

Use vendored OpenSSL.

Updated dependency:

```toml
openssl = { version = "0.10", features = ["vendored"] }
```

Result:

* OpenSSL cross-compiled cleanly
* no pkg-config dependency
* no Debian linker contamination
* deterministic build

This aligned well with the project's embedded philosophy:

* reproducibility
* controlled dependencies
* deployment-owned binaries

## Final Successful Build

Successful ARM build:

```bash
cargo build --release
```

Transferred binary:

```text
target/armv7-unknown-linux-gnueabihf/release/rust-tls-test
```

Deployment:

```bash
rsync -avz \
  target/armv7-unknown-linux-gnueabihf/release/rust-tls-test \
  debian@<bbb-ip>:/opt/IoTEdge/bin/
```

## Runtime Validation

Executed successfully on BBB:

```bash
./rust-tls-test
```

Output:

```text
OpenSSL version: OpenSSL 3.6.2 7 Apr 2026
```

Important observation:

Vendored OpenSSL resulted in:

```text
OpenSSL 3.6.2
```

instead of target system OpenSSL 1.1.1d.

Meaning:

* OpenSSL was built directly into the application
* target system OpenSSL was NOT required
* deployment became more self-contained

## Runtime Dependency Check

Verified dynamic linkage:

```bash
ldd rust-tls-test
```

Observed runtime dependencies:

```text
libgcc_s.so.1
librt.so.1
libpthread.so.0
libdl.so.2
libc.so.6
```

No dependency on system OpenSSL libraries.

Meaning:

* vendored OpenSSL linked successfully
* runtime dependency footprint simplified

## Key Embedded Linux Lessons Learned

### 1. Runtime Rootfs != SDK

A running Linux filesystem is not automatically a usable cross-compilation SDK.

### 2. pkg-config Is Often the Real Problem

Cross-compilation failures frequently come from:

* incorrect `.pc` metadata
* sysroot rewriting
* linker path contamination

not from the compiler itself.

### 3. Debian Multiarch Adds Complexity

Debian ARM layouts use:

```text
/usr/lib/arm-linux-gnueabihf
/usr/include/arm-linux-gnueabihf
```

which complicates hybrid SDK usage.

### 4. Avoid Mixing Runtime Libraries

Mixing:

* libc
* pthread
* static runtime archives

across unrelated sysroots is dangerous.

### 5. Vendored Native Dependencies Can Be Valuable

Vendored OpenSSL reduced:

* pkg-config complexity
* linker contamination
* runtime dependency issues

and improved reproducibility.

### Current Status

Successfully validated:

* ARMv7 Rust cross-compilation
* Bootlin toolchain integration
* Rust + OpenSSL builds
* Embedded deployment workflow
* rsync deployment strategy
* Runtime compatibility on BBB

This environment is now considered suitable for:

* thin-edge.io build attempts
* Rust MQTT applications
* secure telemetry services
* embedded Rust daemons
* OTA-related tooling

### Future Improvements

Potential future evolution:

#### Buildroot SDK

Would provide:

* coherent sysroot
* integrated pkg-config
* cleaner SDK generation
* fewer hybrid sysroot problems

#### Yocto SDK

Long-term option for:

* production images
* OTA systems
* manufacturing
* secure boot
* CI/CD image generation
