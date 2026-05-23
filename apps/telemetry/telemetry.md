# IoTEdge telemetry app

This Python app publishes BeagleBone Black system telemetry to the local
Mosquitto broker over MQTT.

The app is developed under `apps/telemetry/`. Before deployment, copy it to
`deploy/apps/telemetry/` so the deployment script can stage it under
`/opt/IoTEdge/apps/telemetry/`.

## Layout

```text
apps/telemetry/
|-- .iotedge-app
|-- config.py
|-- metrics/
|   |-- cpu.py
|   |-- disk.py
|   |-- memory.py
|   |-- network.py
|   `-- uptime.py
|-- requirements.txt
|-- telemetry.md
`-- telemetry.py
```

The `.iotedge-app` marker tells the deployment script that this Python app is
safe to copy from `deploy/apps/telemetry/` into the target runtime.

## Metrics

The app publishes JSON payloads for:

- CPU usage
- Memory usage
- Disk usage
- Uptime
- IP address

Example topics:

```text
device/telemetry/cpu
device/telemetry/memory
device/telemetry/disk
device/telemetry/uptime
device/telemetry/ip_address
device/status
```

The status topic uses MQTT Last Will and Testament. The app publishes `online`
after connecting, and the broker publishes `offline` if the app disconnects
unexpectedly.

## Target packages

Install these packages on the BeagleBone Black:

```bash
sudo apt install python3 python3-paho-mqtt python3-psutil
```

## Deploy

Prepare the Python app for deployment:

```bash
mkdir -p deploy/apps
cp -a apps/telemetry deploy/apps/
```

Deploy the runtime:

```bash
./scripts/rsync.sh <BBB_IP>
```

For the full deployment workflow, see
[`docs/deployment.md`](../../docs/deployment.md).

## Run manually

Run the app on the target:

```bash
/usr/bin/python3 /opt/IoTEdge/apps/telemetry/telemetry.py
```

Observe MQTT messages:

```bash
/opt/IoTEdge/bin/mosquitto_sub -v -t 'device/#'
```

## Service logs

When running as a systemd service, check logs with:

```bash
journalctl -u iotedge-telemetry.service -f
```
