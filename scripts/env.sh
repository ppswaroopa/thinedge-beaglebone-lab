#!/usr/bin/env bash

# Project root
export PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Toolchain root
export TOOLCHAIN_ROOT="$PROJECT_ROOT/toolchains/armv7-eabihf--glibc--stable-2018.11-1"

# Target sysroot
export SYSROOT="$TOOLCHAIN_ROOT/arm-buildroot-linux-gnueabihf/sysroot"

# Toolchain binaries
export PATH="$TOOLCHAIN_ROOT/bin:$PATH"

# Cross compiler for C/C++
export CC=arm-buildroot-linux-gnueabihf-gcc
export CXX=arm-buildroot-linux-gnueabihf-g++

# Binutils
export AR=arm-buildroot-linux-gnueabihf-ar
export LD=arm-buildroot-linux-gnueabihf-ld
export STRIP=arm-buildroot-linux-gnueabihf-strip

# Rust cross-compilation
export CARGO_TARGET_ARMV7_UNKNOWN_LINUX_GNUEABIHF_LINKER=$CC

export CC_armv7_unknown_linux_gnueabihf=$CC
export CXX_armv7_unknown_linux_gnueabihf=$CXX

# pkg-config cross-compilation support
export PKG_CONFIG_ALLOW_CROSS=1
export PKG_CONFIG_SYSROOT_DIR=$SYSROOT
export BBB_SYSROOT=$PROJECT_ROOT/sysroots/bbb

# OpenSSL only
export OPENSSL_DIR=$BBB_SYSROOT/usr

export OPENSSL_INCLUDE_DIR=$BBB_SYSROOT/usr/include
export CFLAGS="--sysroot=$SYSROOT -I$BBB_SYSROOT/usr/include/arm-linux-gnueabihf"
export CXXFLAGS="$CFLAGS"

export PKG_CONFIG_PATH="$SYSROOT/usr/lib/arm-linux-gnueabihf/pkgconfig:$SYSROOT/usr/share/pkgconfig"

export PKG_CONFIG_LIBDIR="$PKG_CONFIG_PATH"

export CARGO_BUILD_TARGET=armv7-unknown-linux-gnueabihf

echo "Embedded SDK environment loaded"
echo "PROJECT_ROOT=$PROJECT_ROOT"
echo "TOOLCHAIN_ROOT=$TOOLCHAIN_ROOT"
echo "SYSROOT=$SYSROOT"
echo "CC=$CC"
echo "CXX=$CXX"

if [ ! -d "$SYSROOT/usr" ]; then
    echo "Warning: target sysroot not found at $SYSROOT" >&2
    echo "Create it with the rsync commands in sysroots/README.md" >&2
fi
