#!/usr/bin/env bash

# Project root
export PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Toolchain root
export TOOLCHAIN_ROOT="$PROJECT_ROOT/toolchains/armv7-eabihf--glibc--stable-2018.11-1"

# Target sysroot copied from the BeagleBone Black
export SYSROOT="$TOOLCHAIN_ROOT/arm-buildroot-linux-gnueabihf/sysroot"

# Toolchain binaries
export PATH="$TOOLCHAIN_ROOT/bin:$PATH"

# Cross compiler
export CC=arm-buildroot-linux-gnueabihf-gcc
export CXX=arm-buildroot-linux-gnueabihf-g++

# pkg-config support
export PKG_CONFIG_SYSROOT_DIR="$SYSROOT"
export PKG_CONFIG_PATH="$SYSROOT/usr/lib/pkgconfig:$SYSROOT/usr/share/pkgconfig"
export PKG_CONFIG_LIBDIR="$SYSROOT/usr/lib/pkgconfig"

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
