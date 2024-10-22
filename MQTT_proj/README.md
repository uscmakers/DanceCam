# MQTT Client for RPi

This package provides MQTT publishing and subscribing capabilities for our RPi project.

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

See example.py for basic usage.

## Configuration

Edit config.py to modify MQTT broker settings and topics.
"""
