#!/usr/bin/env python3

import json
import logging
import signal
import time

import paho.mqtt.client as mqtt

from config import DEVICE_ID
from config import MQTT_BROKER
from config import MQTT_KEEPALIVE_SECONDS
from config import MQTT_PORT
from config import PUBLISH_INTERVAL_SECONDS
from config import STATUS_TOPIC
from metrics import collect_metrics

running = True
connected = False


def handle_shutdown(signum, frame):
    global running
    running = False


def on_connect(client, userdata, flags, rc):
    global connected

    if rc != 0:
        connected = False
        logging.warning("MQTT broker rejected connection: rc=%s", rc)
        return

    connected = True
    client.publish(STATUS_TOPIC, "online", retain=True)
    logging.info("Telemetry agent is online")


def on_disconnect(client, userdata, rc):
    global connected

    connected = False

    if rc == 0:
        logging.info("MQTT client disconnected cleanly")
        return

    logging.warning("MQTT client disconnected unexpectedly: rc=%s", rc)


def build_payload(metric):
    return {
        "device": DEVICE_ID,
        "metric": metric["name"],
        "value": metric["value"],
        "unit": metric["unit"],
        "timestamp": int(time.time()),
    }


def publish_metric(client, metric):
    topic = f"device/telemetry/{metric['name']}"
    payload = json.dumps(build_payload(metric), separators=(",", ":"))
    result = client.publish(topic, payload)

    if result.rc != mqtt.MQTT_ERR_SUCCESS:
        logging.warning("Failed to publish %s: rc=%s", topic, result.rc)
        return

    logging.info("Published %s %s %s", metric["name"], metric["value"], metric["unit"])


def create_client():
    client = mqtt.Client(client_id=f"{DEVICE_ID}-telemetry")
    client.will_set(STATUS_TOPIC, payload="offline", retain=True)
    client.on_connect = on_connect
    client.on_disconnect = on_disconnect
    client.reconnect_delay_set(min_delay=1, max_delay=30)
    return client


def connect(client):
    while running:
        try:
            logging.info("Connecting to MQTT broker %s:%s", MQTT_BROKER, MQTT_PORT)
            client.connect(MQTT_BROKER, MQTT_PORT, MQTT_KEEPALIVE_SECONDS)
            client.loop_start()
            return
        except OSError as exc:
            logging.warning("MQTT connection failed: %s", exc)
            time.sleep(5)


def publish_metrics(client):
    if not connected:
        logging.warning("Skipping publish while MQTT client is offline")
        return

    for metric in collect_metrics():
        publish_metric(client, metric)


def main():
    logging.basicConfig(
        format="%(asctime)s %(levelname)s %(message)s",
        level=logging.INFO,
    )

    signal.signal(signal.SIGINT, handle_shutdown)
    signal.signal(signal.SIGTERM, handle_shutdown)

    client = create_client()
    connect(client)

    while running:
        try:
            publish_metrics(client)
        except Exception:
            logging.exception("Telemetry publish loop failed")

        time.sleep(PUBLISH_INTERVAL_SECONDS)

    logging.info("Telemetry agent is shutting down")
    client.publish(STATUS_TOPIC, "offline", retain=True)
    client.loop_stop()
    client.disconnect()


if __name__ == "__main__":
    main()
