#!/usr/bin/env bash

set -euo pipefail

runtime_root="${IOTEDGE_ROOT:-/opt/IoTEdge}"
service_src="$runtime_root/services"
systemd_dst="/etc/systemd/system"

log() {
    printf '[iotedge-services] %s\n' "$*"
}

fail() {
    printf '[iotedge-services] ERROR: %s\n' "$*" >&2
    exit 1
}

if [ ! -d "$service_src" ]; then
    fail "Service directory not found: $service_src"
fi

if ! command -v systemctl >/dev/null 2>&1; then
    fail "systemctl is not available on this target."
fi

log "Installing IoTEdge systemd services from $service_src."

for service_file in "$service_src"/*.service; do
    if [ ! -e "$service_file" ]; then
        fail "No .service files found in $service_src"
    fi

    service_name="$(basename "$service_file")"
    log "Installing $service_name -> $systemd_dst/$service_name"
    sudo install -m 0644 "$service_file" "$systemd_dst/$service_name"
done

log "Reloading systemd."
sudo systemctl daemon-reload

log "Enabling IoTEdge services."
for service_file in "$service_src"/*.service; do
    service_name="$(basename "$service_file")"
    sudo systemctl enable "$service_name"
done

log "Service installation complete."
log "Start a service with: sudo systemctl start <service-name>"
