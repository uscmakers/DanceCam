# mqtt_client/publisher.py
import paho.mqtt.client as mqtt
import json
from datetime import datetime


class MQTTPublisher:
    def __init__(self, broker="localhost", port=1883):
        self.client_id = f"publisher_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        self.client = mqtt.Client(client_id=self.client_id)
        self.broker = broker
        self.port = port

        self.client.on_connect = self._on_connect
        self.client.on_disconnect = self._on_disconnect

    def _on_connect(self, client, userdata, flags, rc):
        if rc == 0:
            print(f"Publisher connected to broker {self.broker}")
        else:
            print(f"Connection failed with code {rc}")

    def _on_disconnect(self, client, userdata, rc):
        if rc != 0:
            print("Unexpected disconnection. Attempting to reconnect...")

    def connect(self):
        try:
            self.client.connect(self.broker, self.port, 60)
            self.client.loop_start()
        except Exception as e:
            print(f"Connection error: {e}")

    def publish(self, topic, message, qos=0):
        try:
            if isinstance(message, (dict, list)):
                message = json.dumps(message)
            self.client.publish(topic, message, qos)
        except Exception as e:
            print(f"Error publishing message: {e}")

    def disconnect(self):
        self.client.loop_stop()
        self.client.disconnect()
