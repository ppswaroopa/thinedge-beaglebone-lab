# Deployment workflow

This document describes how runtime artifacts are staged and deployed to the
BeagleBone Black.

Build artifacts before following this workflow. For the Mosquitto build, see
[`docs/mosquitto-cross-compilation.md`](mosquitto-cross-compilation.md).

## Overview

The deployment workflow uses a host-generated root filesystem overlay. Files
are built on the host, copied into a deterministic directory tree, and synced to
the target device.

```text
Host machine
    |
    v
Cross-compiled runtime artifacts
    |
    v
deploy/rootfs/
    |
    v
rsync
    |
    v
BeagleBone Black /opt/IoTEdge
```

## Goals

- Build runtime artifacts on the host machine.
- Deploy only the files needed at runtime.
- Keep application files out of system directories.
- Make deployment repeatable.
- Prepare the project for automation, packaging, and CI.

## Runtime root

The target runtime is installed under:

```text
/opt/IoTEdge
```

Using `/opt/IoTEdge` keeps the deployment self-contained and easy to remove or
replace. It also avoids mixing lab-built binaries with Debian packages under
`/usr` or `/usr/local`.

## Repository layout

Use `deploy/rootfs/` as a mirror of the target filesystem paths.

```text
deploy/
`-- rootfs/
    `-- opt/
        `-- IoTEdge/
            |-- apps/
            |-- bin/
            |-- config/
            |-- data/
            |-- lib/
            |-- logs/
            |-- scripts/
            |-- services/
            `-- third_party/
```

The deployment tree should contain generated runtime artifacts only. Source
code, build directories, and toolchains should stay on the host.

## Runtime layout

The expected target layout is:

```text
/opt/IoTEdge/
|-- apps/
|   `-- telemetry/
|-- bin/
|   |-- mosquitto
|   |-- mosquitto_pub
|   |-- mosquitto_rr
|   `-- mosquitto_sub
|-- config/
|   `-- mosquitto/
|-- data/
|-- lib/
|   |-- libcjson.so.1
|   `-- libmosquitto.so.1
|-- logs/
|-- scripts/
|   `-- install-services.sh
|-- services/
|   |-- iotedge-mosquitto.service
|   `-- iotedge-telemetry.service
`-- third_party/
    |-- cjson/
    `-- mosquitto/
```

Place applications in `apps/`, executable programs in `bin`, shared libraries
in `lib/`, and runtime configuration in `config/<package>/`. Target-side helper
scripts live in `scripts/`, and systemd units live in `services/`. The full
staged install tree for each package is also preserved under
`third_party/<package>/`.

## Deploy with the script

The deployment script is the canonical way to stage and sync runtime artifacts.
It validates that Mosquitto and cJSON have been generated, creates the host
overlay under `deploy/rootfs/opt/IoTEdge`, copies runtime files into the
overlay, prints the staged layout, and syncs the overlay to the target.

Run it from the repository root:

```bash
./scripts/rsync.sh <BBB_IP>
```

Replace `<BBB_IP>` with the target IP address or hostname.

To prepare and inspect the host overlay without syncing to a target, run:

```bash
./scripts/rsync.sh --stage-only
```

The script uses the `debian` SSH user by default. Override it with
`TARGET_USER`:

```bash
TARGET_USER=debian ./scripts/rsync.sh <BBB_IP>
```

The script does not use remote `sudo`. Prepare the target once so the deploy
user can write to `/opt/IoTEdge`:

```bash
sudo mkdir -p /opt/IoTEdge
sudo chown -R debian:debian /opt/IoTEdge
sudo apt install rsync python3 python3-paho-mqtt
```

Replace `debian:debian` with the target user and group when needed.

Use `--clean` to recreate `deploy/rootfs` before staging:

```bash
./scripts/rsync.sh --clean --stage-only
```

The script stages all package install trees found under `third_party/install`.
Override the install source with `INSTALL_ROOT` when needed:

```bash
INSTALL_ROOT=/path/to/install ./scripts/rsync.sh --stage-only
```

The script also stages tracked runtime files from:

- `deploy/apps/`
- `config/`
- `services/`
- `deploy/scripts/`

Use `deploy/apps/<app-name>/` for Python applications that should run directly
on the target. Keep `apps/` for source code and compiled application projects.

## Manual staging reference

Create the deployment directories from the repository root:

```bash
mkdir -p deploy/rootfs/opt/IoTEdge/bin
mkdir -p deploy/rootfs/opt/IoTEdge/apps
mkdir -p deploy/rootfs/opt/IoTEdge/config
mkdir -p deploy/rootfs/opt/IoTEdge/lib
mkdir -p deploy/rootfs/opt/IoTEdge/logs
mkdir -p deploy/rootfs/opt/IoTEdge/third_party
```

Copy package install trees into the deployment tree:

```bash
cp -a third_party/install/* deploy/rootfs/opt/IoTEdge/third_party/
```

Promote runtime binaries, libraries, and configuration into the top-level
runtime directories:

```bash
cp -a third_party/install/*/bin/. \
    deploy/rootfs/opt/IoTEdge/bin/ 2>/dev/null || true
cp -a third_party/install/*/sbin/. \
    deploy/rootfs/opt/IoTEdge/bin/ 2>/dev/null || true
cp -a third_party/install/*/lib/. \
    deploy/rootfs/opt/IoTEdge/lib/ 2>/dev/null || true
cp -a third_party/install/*/etc/. \
    deploy/rootfs/opt/IoTEdge/config/ 2>/dev/null || true
```

Sync the staged overlay manually when needed:

```bash
rsync -az --no-owner --no-group \
    deploy/rootfs/opt/IoTEdge/ debian@<BBB_IP>:/opt/IoTEdge/
```

## Run on the target

Log in to the BeagleBone Black and point the runtime linker at the deployed
library directory:

```bash
export LD_LIBRARY_PATH=/opt/IoTEdge/lib:${LD_LIBRARY_PATH:-}
```

Start Mosquitto:

```bash
/opt/IoTEdge/bin/mosquitto \
    -c /opt/IoTEdge/config/mosquitto/mosquitto.conf
```

To install tracked systemd service files after deployment, run:

```bash
/opt/IoTEdge/scripts/install-services.sh
```

Start the MQTT broker service:

```bash
sudo systemctl start iotedge-mosquitto.service
```

Check service status:

```bash
systemctl status iotedge-mosquitto.service
```

For a quick smoke test without a configuration file, use:

```bash
/opt/IoTEdge/bin/mosquitto -c /dev/null
```

## Runtime dependencies

System libraries such as `libc`, `libm`, `libdl`, and `libpthread` are provided
by the target OS. Custom-built libraries are deployed with the application.

For the minimal Mosquitto build used in this project, `libcjson.so.1` is a
custom runtime dependency and must be present under `/opt/IoTEdge/lib`.

## Future improvements

- Add systemd service files under `deploy/rootfs/etc/systemd/system/`.
- Generate deployment scripts from a single manifest.
- Package runtime artifacts as Debian packages.
- Add CI checks for deployment contents.
