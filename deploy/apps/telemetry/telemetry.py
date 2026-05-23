import time
import random
import socket
import paho.mqtt.client as mqtt

BROKER = "localhost"
PORT = 1883

TOPIC_TEMP = "device/telemetry/temp"
TOPIC_STATUS = "device/status"

hostname = socket.gethostname()

client = mqtt.Client()
client.connect(BROKER, PORT, 60)

while True:
    temp = round(random.uniform(20.0, 35.0), 2)

    client.publish(TOPIC_TEMP, temp)
    client.publish(TOPIC_STATUS, "online")

    print(f"[{hostname}] temp={temp}")

    time.sleep(5)