# mqtt_client/subscriber.py
import paho.mqtt.client as mqtt
import json


class MQTTSubscriber:
    def __init__(self, broker="localhost", port=1883):
        self.client_id = f"subscriber_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        self.client = mqtt.Client(client_id=self.client_id)
        self.broker = broker
        self.port = port
        self.topic_handlers = {}

        self.client.on_connect = self._on_connect
        self.client.on_message = self._on_message

    def _on_connect(self, client, userdata, flags, rc):
        if rc == 0:
            print(f"Subscriber connected to broker {self.broker}")
            # Resubscribe to topics on reconnection
            for topic in self.topic_handlers.keys():
                self.client.subscribe(topic)
        else:
            print(f"Connection failed with code {rc}")

    def _on_message(self, client, userdata, msg):
        try:
            payload = json.loads(msg.payload.decode())
        except json.JSONDecodeError:
            payload = msg.payload.decode()

        if msg.topic in self.topic_handlers:
            self.topic_handlers[msg.topic](payload)
        else:
            print(f"Received on {msg.topic}: {payload}")

    def connect(self):
        try:
            self.client.connect(self.broker, self.port, 60)
            self.client.loop_start()
        except Exception as e:
            print(f"Connection error: {e}")

    def subscribe(self, topic, handler=None):
        self.client.subscribe(topic)
        if handler:
            self.topic_handlers[topic] = handler

    def disconnect(self):
        self.client.loop_stop()
        self.client.disconnect()
