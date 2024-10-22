# MQTT Client for Raspberry Pi

This project implements an MQTT client for publishing and subscribing to sensor data on a Raspberry Pi. It provides a modular structure for handling MQTT communications with clean configuration management.

## Project Structure

```
mqtt_project/
├── requirements.txt      # Package dependencies
├── config.py            # Configuration settings
├── mqtt_test.py         # Test/example file
├── mqtt_client/         # Main package directory
│   ├── __init__.py     
│   ├── publisher.py    
│   └── subscriber.py   
├── .gitignore          # Git ignore file
└── README.md           # Project documentation
```

## Setup Instructions

### 1. Install MQTT Broker
On your Raspberry Pi, install the Mosquitto MQTT broker:
```bash
sudo apt-get update
sudo apt-get install mosquitto mosquitto-clients
sudo systemctl enable mosquitto
sudo systemctl start mosquitto
```

### 2. Clone Repository
```bash
git clone <your-repo-url>
cd <your-repo-directory>
```

### 3. Set Up Python Environment
```bash
# Create virtual environment
python3 -m venv venv

# Activate virtual environment
source venv/bin/activate

# Install required packages
pip install -r requirements.txt
```

### 4. Test Installation
```bash
# Make sure you're in the project directory and virtual environment is activated
python mqtt_test.py
```
You should see messages being published and received with test temperature and humidity data.

## Configuration

Edit `config.py` to modify:
- MQTT broker address
- Port number
- Topic names
- Other MQTT settings

## Usage

### Basic Usage Example
```python
from mqtt_client.publisher import MQTTPublisher
from mqtt_client.subscriber import MQTTSubscriber
from config import MQTT_CONFIG

# Create and connect subscriber
subscriber = MQTTSubscriber(
    broker=MQTT_CONFIG['broker'],
    port=MQTT_CONFIG['port']
)
subscriber.connect()
subscriber.subscribe('sensors/temperature')

# Create and connect publisher
publisher = MQTTPublisher(
    broker=MQTT_CONFIG['broker'],
    port=MQTT_CONFIG['port']
)
publisher.connect()

# Publish a message
publisher.publish('sensors/temperature', '25.5')
```

## Development

### Adding New Topics
1. Add new topic to `config.py`
2. Create handler function for the topic
3. Subscribe to topic with handler

### Error Handling
The client includes built-in error handling and reconnection logic for:
- Connection failures
- Network interruptions
- Message parsing errors

## Troubleshooting

1. Check if MQTT broker is running:
```bash
sudo systemctl status mosquitto
```

2. Test MQTT manually:
```bash
# Subscribe to test topic
mosquitto_sub -t "test/topic"

# In another terminal, publish to test topic
mosquitto_pub -t "test/topic" -m "test message"
```

3. Check logs:
```bash
# Check Mosquitto logs
sudo tail -f /var/log/mosquitto/mosquitto.log
```
