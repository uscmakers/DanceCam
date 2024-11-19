# Importing required packages
import sys
import os

# Import all functions form Motor.py
from Motor import *

# Importing flask stuff
from flask import Flask, request, jsonify

# Initiating a Flask application
app = Flask(__name__)

# def process_json(data):
#     img_width = 1080
#     distance = data['distance']
#     speed = (abs(distance)/2.0/img_width)*4096
#     direction = 1 if distance > 0 else -1
#     return math.floor(speed*direction)

"""
    Endpoint for sending signal to motors
"""


@app.route(rule="/move", methods=["POST"])
def handle_move_request():
    PWM = Motor()

    data = request.get_json()

    # make sure there are 4 numbers
    try:
        # duty_cycle = process_json(data)
        duty1 = data['duty1']
        duty2 = data['duty2']
        duty3 = data['duty3']
        duty4 = data['duty4']
    except ValueError:
        return jsonify({"error": "All values must be numbers"}), 400

    PWM.setMotorModel(duty1, duty2, duty3, duty4)

    return jsonify({"status": "Successfully triggered motors"})


"""
    Endpoint for stopping all motors
"""


@app.route(rule="/stop", methods=["POST"])
def handle_stop_request():
    PWM = Motor()

    # set all motors to 0, stops all movement
    PWM.setMotorModel(0, 0, 0, 0)

    # successful message
    return jsonify({"status": "Successfully stopped all motors"})


# Running the API
if __name__ == "__main__":
    # Setting host = "0.0.0.0" runs it on localhost
    app.run(host="0.0.0.0", port=8000, debug=True)
