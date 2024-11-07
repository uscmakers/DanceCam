from mqtt_client.publisher import MQTTPublisher
from mqtt_client.subscriber import MQTTSubscriber
from config import MQTT_CONFIG
import time
import signal
import sys


def handle_temperature(payload):
    """Example handler for temperature messages"""
    print(f"Temperature reading: {payload}°C")


def handle_humidity(payload):
    """Example handler for humidity messages"""
    print(f"Humidity reading: {payload}%")


def handle_exit(signum, frame):
    """Handle clean exit on CTRL+C"""
    print("\nExiting gracefully...")
    if "subscriber" in globals():
        subscriber.disconnect()
    if "publisher" in globals():
        publisher.disconnect()
    sys.exit(0)


def main():
    # Set up signal handler for graceful exit
    signal.signal(signal.SIGINT, handle_exit)

    # Create subscriber
    subscriber = MQTTSubscriber(broker=MQTT_CONFIG["broker"], port=MQTT_CONFIG["port"])

    # Create publisher
    publisher = MQTTPublisher(broker=MQTT_CONFIG["broker"], port=MQTT_CONFIG["port"])

    try:
        # Connect subscriber and set up handlers
        subscriber.connect()
        subscriber.subscribe(
            MQTT_CONFIG["topics"]["temperature"], handler=handle_temperature
        )
        subscriber.subscribe(MQTT_CONFIG["topics"]["humidity"], handler=handle_humidity)

        # Connect publisher
        publisher.connect()

        print("MQTT Test Client Running...")
        print("Publishing test messages every 5 seconds...")
        print("Press CTRL+C to exit")

        # Main loop - publish test messages
        while True:
            # Publish test temperature
            publisher.publish(MQTT_CONFIG["topics"]["temperature"], "25.5")

            # Publish test humidity
            publisher.publish(MQTT_CONFIG["topics"]["humidity"], "60")

            # Publish test JSON data
            publisher.publish(
                MQTT_CONFIG["topics"]["sensors"],
                {
                    "temperature": 25.5,
                    "humidity": 60,
                    "timestamp": time.strftime("%Y-%m-%d %H:%M:%S"),
                },
            )

            time.sleep(5)

    except Exception as e:
        print(f"Error: {e}")
        subscriber.disconnect()
        publisher.disconnect()


if __name__ == "__main__":
    main()
