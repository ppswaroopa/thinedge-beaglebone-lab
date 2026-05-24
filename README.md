# thin-edge.io BeagleBone Lab

A home IoT gateway lab that uses thin-edge.io on a BeagleBone Black.

![Status: build ready](https://img.shields.io/badge/status-build%20ready-blue)
![Version: 0.1.0](https://img.shields.io/badge/version-0.1.0-blue)
![License: MIT](https://img.shields.io/badge/license-MIT-green)
![Hardware: BeagleBone Black](https://img.shields.io/badge/hardware-BeagleBone%20Black-black)
![OS: Debian](https://img.shields.io/badge/os-Debian-red)
![Edge runtime: thin-edge.io](https://img.shields.io/badge/edge-thin--edge.io-blue)
![Messaging: MQTT](https://img.shields.io/badge/messaging-MQTT-purple)
![Dashboard: Node-RED](https://img.shields.io/badge/dashboard-Node--RED-red)
![Build: CMake and Ninja](https://img.shields.io/badge/build-CMake%20%2B%20Ninja-green)

## Progress

- [x] Cross-compilation workflow
- [x] MQTT fundamentals
- [x] thin-edge.io integration
- [x] Dashboard and visualization
- [ ] Industrial gateway simulation
- [ ] Cloud integration
- [ ] Containerization
- [ ] Yocto familiarity

## Overview

This repository tracks a practical, industrial-style IoT and edge gateway
learning project that focuses on embedded Linux, MQTT telemetry, thin-edge.io,
dashboards, cloud connectivity, cross-compilation, and deployment workflows.
The first completed milestone is a working BeagleBone Black cross-compilation
workflow.

## Goals

- Build an edge gateway lab that can run at home.
- Learn embedded Linux concepts on a BeagleBone Black.
- Practice industrial gateway workflows with MQTT and thin-edge.io.
- Explore dashboards, cloud connectivity, and cross-compilation.

## Hardware and software

- BeagleBone Black
- Debian
- thin-edge.io
- MQTT
- Node-RED
- Docker or Podman
- ARM cross-compilation toolchain

## Repository structure

Possible folder structure:

```text
edge-lab/
|-- apps/
|-- dashboards/
|-- docker/
|-- docs/
|-- mqtt/
|-- scripts/
|-- services/
|-- sysroots/
|-- telemetry/
|-- toolchains/
`-- README.md
```

## Build setup

Set up the cross-compilation toolchain before building target applications.

1. Download the Bootlin ARMv7 hard-float toolchain.
1. Extract it under `toolchains/`.
1. Copy the target sysroot from the BeagleBone Black:

   ```bash
   mkdir -p sysroots/bbb/usr
   rsync -avz --delete debian@<BBB_IP>:/lib/ sysroots/bbb/lib/
   rsync -avz --delete debian@<BBB_IP>:/usr/include/ sysroots/bbb/usr/include/
   rsync -avz --delete debian@<BBB_IP>:/usr/lib/ sysroots/bbb/usr/lib/
   ```

1. Load the embedded SDK environment:

   ```bash
   source scripts/env.sh
   ```

1. Configure applications with
   [`toolchains/bbb-armhf.cmake`](toolchains/bbb-armhf.cmake).

For details, see [`toolchains/README.md`](toolchains/README.md),
[`sysroots/README.md`](sysroots/README.md), and
[`docs/cross-compilation.md`](docs/cross-compilation.md).

## Documentation

Use these documents in order when replicating the current workflow:

1. [`toolchains/README.md`](toolchains/README.md): install the Bootlin ARM
   toolchain used by this lab.
1. [`sysroots/README.md`](sysroots/README.md): copy the target sysroot from the
   BeagleBone Black.
1. [`docs/cross-compilation.md`](docs/cross-compilation.md): understand the
   BeagleBone Black cross-compilation workflow and ABI constraints.
1. [`docs/mosquitto-cross-compilation.md`](docs/mosquitto-cross-compilation.md):
   build Mosquitto and its cJSON dependency for the target.
1. [`docs/deployment.md`](docs/deployment.md): stage runtime artifacts and
   deploy them to `/opt/IoTEdge`.

## Roadmap

### Phase 0: Foundation setup

#### Phase 0 objectives

Understand:

- Linux on embedded devices
- Networking basics
- systemd services
- MQTT fundamentals

#### Phase 0 tasks

Install and update the BeagleBone Black with the required development tools:

```bash
sudo apt update
sudo apt install git build-essential python3 python3-pip cmake curl
```

#### Phase 0 deliverables

- Working Debian installation on the BeagleBone Black
- SSH access
- Git repository
- Base development tools

### Phase 1: MQTT fundamentals

#### Phase 1 objectives

Learn:

- Publish and subscribe workflows
- Telemetry topics
- Device state topics
- Retained messages
- Quality of service
- MQTT tooling

#### Phase 1 components

| Component | Purpose |
| --- | --- |
| Eclipse Mosquitto | MQTT broker |
| MQTT Explorer | Topic visualization |
| Python MQTT client | Telemetry publisher |

#### Phase 1 tasks

Install Mosquitto on the laptop or BeagleBone Black:

```bash
sudo apt install mosquitto mosquitto-clients
```

Publish a test message:

```bash
mosquitto_pub -t test/topic -m "hello"
```

Subscribe to the test topic:

```bash
mosquitto_sub -t test/topic
```

Build a Python telemetry publisher with `paho-mqtt`. Example telemetry:

- Temperature
- CPU usage
- Uptime
- Simulated robot state

#### Phase 1 deliverables

- MQTT topic hierarchy
- Telemetry publisher
- Subscriber tools
- Setup documentation

### Phase 2: thin-edge.io integration

#### Phase 2 objectives

Learn:

- Edge runtime architecture
- MQTT bridge concepts
- Device state management

#### Phase 2 components

| Component | Purpose |
| --- | --- |
| thin-edge.io | Lightweight edge agent |
| Mosquitto | MQTT transport |

#### Phase 2 tasks

Install thin-edge.io by following the
[thin-edge.io documentation](https://thin-edge.github.io/thin-edge.io/).

Explore:

- `tedge` commands
- Service architecture
- MQTT topics
- Telemetry format
- Health monitoring

Publish sample device data:

- CPU temperature
- Memory usage
- Network status
- Simulated industrial sensor values

#### Phase 2 deliverables

- Documented setup
- Service diagrams
- MQTT flow documentation

### Phase 3: Dashboard and visualization

#### Phase 3 objectives

Build an operator-style monitoring UI.

#### Phase 3 components

| Component | Purpose |
| --- | --- |
| Node-RED | Dashboard |
| MQTT broker | Telemetry backend |

#### Phase 3 tasks

Install Node-RED on the laptop.

Build dashboard widgets for:

- Device online and offline state
- Telemetry graphs
- Alarms
- Uptime
- Command buttons

Add control commands for:

- Toggling a BeagleBone Black LED
- Restarting a service
- Triggering an alarm simulation

#### Phase 3 deliverables

- Dashboard screenshots
- Exported Node-RED flows
- Architecture diagrams

### Phase 4: Industrial gateway simulation

#### Phase 4 objectives

Simulate common industrial edge workflows.

#### Phase 4 concepts

Maintain a device twin with:

- Current state
- Desired state
- Configuration

Build an alarm system for:

- Temperature thresholds
- Disconnect detection
- CPU overload

Simulate offline buffering with:

- Network outage handling
- Delayed uploads
- Reconnect logic

Use watchdog behavior for:

- systemd restart policies
- Process supervision

#### Phase 4 deliverables

- Resilient telemetry pipeline
- Recovery logic
- Watchdog services

### Phase 5: Cross-compilation

#### Phase 5 objectives

Replicate embedded Linux build workflows.

#### Phase 5 concepts

Learn:

- Host and target differences
- ARM toolchains
- Sysroots
- Deployment

#### Phase 5 tasks

Follow the documented workflow in
[`docs/cross-compilation.md`](docs/cross-compilation.md).

Set up the Bootlin ARMv7 hard-float toolchain by following
[`toolchains/README.md`](toolchains/README.md).

Copy the target sysroot by following
[`sysroots/README.md`](sysroots/README.md).

Load the embedded SDK environment from the repository root:

```bash
source scripts/env.sh
```

Use the project CMake toolchain file:

- [`toolchains/bbb-armhf.cmake`](toolchains/bbb-armhf.cmake)

Configure and build an application:

```bash
cmake ../apps/hello_arm \
    -DCMAKE_TOOLCHAIN_FILE=../toolchains/bbb-armhf.cmake \
    -G Ninja
ninja
```

Copy the application to the BeagleBone Black:

```bash
scp app debian@bbb-ip:/home/debian
```

Create a reusable CMake toolchain file:

- `toolchain.cmake`

Learn:

- Target compilers
- Sysroot usage

#### Phase 5 deliverables

- Cross-compiled binaries
- Reusable toolchain files
- Deployment scripts

### Phase 6: Cloud integration

#### Phase 6 objectives

Learn cloud-connected IoT workflows.

#### Cloud service order

1. [HiveMQ Cloud](https://www.hivemq.com/mqtt-cloud-broker/)
1. [EMQX Cloud](https://www.emqx.com/en/cloud)
1. [Azure IoT Hub](https://azure.microsoft.com/products/iot-hub/)

Start with HiveMQ Cloud to learn TLS, credentials, and remote MQTT. Move to
Azure IoT Hub after the MQTT fundamentals are solid.

#### Phase 6 deliverables

- Secure MQTT connection
- Remote telemetry
- Cloud dashboards

### Phase 7: Containerization

#### Phase 7 objectives

Understand modern edge deployment.

#### Phase 7 concepts

Learn:

- Docker
- Podman
- Compose
- Edge services

#### Phase 7 tasks

Containerize:

- Telemetry application
- MQTT bridge
- Dashboard services

#### Phase 7 deliverables

- Container definitions
- Local compose workflow
- Service deployment notes

### Phase 8: Yocto familiarity

#### Phase 8 objectives

Understand production embedded Linux.

#### Phase 8 concepts

| Concept | Meaning |
| --- | --- |
| BSP | Board support package |
| Layer | Yocto metadata |
| Recipe | Package build instructions |
| Image | Generated Linux distribution |
| SDK | Cross-compiler package |

#### Yocto suggested path

- Build a minimal Yocto image for the BeagleBone Black.
- Compare the image with the Debian setup.
- Understand vendor SDK workflows.

#### Phase 8 deliverables

- Yocto build notes
- Debian and Yocto comparison
- SDK workflow notes

## Milestone projects

### Project 1: Device telemetry agent

Device telemetry agent features:

- CPU, memory, and temperature telemetry
- MQTT publishing
- Service status reporting

### Project 2: Industrial dashboard

Industrial dashboard features:

- Live telemetry
- Alarms
- Device health
- Remote commands

### Project 3: Remote edge gateway

Remote edge gateway features:

- Cloud MQTT
- TLS
- Reconnect handling
- Persistent sessions

### Project 4: Simulated factory gateway

Simulated factory gateway features:

- Multiple simulated sensors
- Machine states
- Fault simulation
- Offline buffering

## Technologies

| Area | Technologies |
| --- | --- |
| Embedded Linux | Debian, Yocto |
| Networking | MQTT, TCP/IP |
| IoT | thin-edge.io |
| Dashboards | Node-RED |
| Build systems | CMake |
| DevOps | Docker, Podman |
| Cloud | Azure IoT Hub, MQTT cloud brokers |
| Embedded build | ARM cross-compilation |
| Monitoring | systemd, logs |

## Long-term outcome

Build practical experience with:

- Industrial IoT
- Robotics infrastructure
- Edge gateways
- Fleet telemetry
- Embedded Linux systems
- Cloud-connected devices
- Production deployment patterns
