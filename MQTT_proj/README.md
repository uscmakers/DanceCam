# MQTT Client for RPi

This is an attempt at providing MQTT publishing and subscribing capabilities for the RPi.

## Installation

1. Install required packages:

   ```bash
   pip install -r requirements.txt
   ```

2. Install MQTT broker on RPi:
   ```bash
   sudo apt-get update
   sudo apt-get install mosquitto mosquitto-clients
   sudo systemctl enable mosquitto
   ```

## Usage
See MQTT_Test.py for a testing file. If that works, we are in good shape.
