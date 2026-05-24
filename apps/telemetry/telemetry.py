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
from metrics import collect_metrics

running = True
connected = False

LED_PATH = "/sys/class/leds/beaglebone:green:usr0/brightness"
TEDGE_TOPIC = "te/device/main///m/system"
COMMAND_TOPIC = "device/command/led"

def set_led(state):
    with open(LED_PATH, "w") as f:
        f.write("1" if state else "0")


def blink_pattern():
    for _ in range(3):
        set_led(True)
        time.sleep(0.15)

        set_led(False)
        time.sleep(0.15)

def handle_shutdown(signum, frame):
    global running
    running = False


def on_connect(client, userdata, flags, rc):
    global connected

    if rc != 0:
        connected = False
        logging.warning("MQTT broker rejected connection: rc=%s", rc)
        return

    client.subscribe(COMMAND_TOPIC)

    connected = True
    logging.info("Telemetry agent connected")

def on_message(client, userdata, msg):
    payload = msg.payload.decode().strip()

    print(f"Command received: {payload}")

    if payload == "blink":
        blink_pattern()

def on_disconnect(client, userdata, rc):
    global connected

    connected = False

    if rc == 0:
        logging.info("MQTT client disconnected cleanly")
        return

    logging.warning("MQTT client disconnected unexpectedly: rc=%s", rc)


def create_client():
    client = mqtt.Client(client_id=f"{DEVICE_ID}-telemetry")
    client.on_connect = on_connect
    client.on_disconnect = on_disconnect
    client.on_message = on_message
    client.reconnect_delay_set(min_delay=1, max_delay=30)
    return client


def connect(client):
    while running:
        try:
            logging.info(
                "Connecting to MQTT broker %s:%s",
                MQTT_BROKER,
                MQTT_PORT,
            )

            client.connect(
                MQTT_BROKER,
                MQTT_PORT,
                MQTT_KEEPALIVE_SECONDS,
            )

            client.loop_start()
            return

        except OSError as exc:
            logging.warning("MQTT connection failed: %s", exc)
            time.sleep(5)


def build_tedge_payload():
    payload = {}

    for metric in collect_metrics():
        payload[metric["name"]] = metric["value"]

    payload["timestamp"] = int(time.time())

    return payload


def publish_telemetry(client):
    if not connected:
        logging.warning("Skipping publish while MQTT client is offline")
        return

    payload = json.dumps(
        build_tedge_payload(),
        separators=(",", ":"),
    )

    result = client.publish(
        TEDGE_TOPIC,
        payload,
        qos=1,
    )

    if result.rc != mqtt.MQTT_ERR_SUCCESS:
        logging.warning(
            "Failed to publish telemetry: rc=%s",
            result.rc,
        )
        return

    logging.info("Published telemetry payload")


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
            publish_telemetry(client)

        except Exception:
            logging.exception("Telemetry publish loop failed")

        time.sleep(PUBLISH_INTERVAL_SECONDS)

    logging.info("Telemetry agent is shutting down")

    client.loop_stop()
    client.disconnect()


if __name__ == "__main__":
    main()