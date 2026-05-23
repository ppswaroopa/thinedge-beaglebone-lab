# Target sysroot

This directory stores local sysroot copies from target devices.

The BeagleBone Black sysroot is copied from the target device with `rsync` and
used by the CMake cross-compilation toolchain. The copied sysroot is ignored by
Git because it contains target system files.

## BeagleBone Black sysroot

Expected layout:

```text
sysroots/
|-- README.md
`-- bbb/
    |-- lib/
    `-- usr/
        |-- include/
        `-- lib/
```

## Create the sysroot

Run these commands from the repository root.

```bash
mkdir -p sysroots/bbb/usr
rsync -avz --delete debian@<BBB_IP>:/lib/ sysroots/bbb/lib/
rsync -avz --delete debian@<BBB_IP>:/usr/include/ sysroots/bbb/usr/include/
rsync -avz --delete debian@<BBB_IP>:/usr/lib/ sysroots/bbb/usr/lib/
```

Replace `<BBB_IP>` with the IP address or hostname of the BeagleBone Black.

## Refresh the sysroot

Rerun the same `rsync` commands after installing new target libraries or header
files on the BeagleBone Black.

Keeping the local sysroot synchronized with the target helps CMake find the same
headers and libraries that exist on the device.
