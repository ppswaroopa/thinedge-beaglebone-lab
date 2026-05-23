import os
import socket

DEVICE_ID = os.getenv("IOTEDGE_DEVICE_ID", socket.gethostname())

MQTT_BROKER = os.getenv("IOTEDGE_MQTT_BROKER", "localhost")
MQTT_PORT = int(os.getenv("IOTEDGE_MQTT_PORT", "1883"))
MQTT_KEEPALIVE_SECONDS = int(os.getenv("IOTEDGE_MQTT_KEEPALIVE_SECONDS", "60"))

PUBLISH_INTERVAL_SECONDS = int(os.getenv("IOTEDGE_PUBLISH_INTERVAL_SECONDS", "5"))

STATUS_TOPIC = os.getenv("IOTEDGE_STATUS_TOPIC", "device/status")
