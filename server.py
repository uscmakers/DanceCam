# Importing required packages
import sys
import os

# Add path to Motor.py
sys.path.append(os.path.abspath("DanceCam/Mecanum"))

# Import all functions form Motor.py
from Motor import *

# Importing flask stuff
from flask import Flask, request, jsonify

# Initiating a Flask application
app = Flask(__name__)

"""
    Simple end point for testing functionality 
"""


@app.route(rule="/", methods=["GET", "POST"])
def handle_request():
    # The GET endpoint
    if request.method == "GET":
        return "This is the GET Endpoint of flask API."

    # The POST endpoint
    if request.method == "POST":
        # accessing the passed payload
        payload = request.get_json()
        # capitalizing the text
        cap_text = payload["text"].upper()
        # Creating a proper response
        response = {"cap-text": cap_text}
        # return the response as JSON
        return jsonify(response)


"""
    Endpoint for sending signal to motors
"""


@app.route(rule="/move", methods=["POST"])
def handle_request():
    PWM = Motor()

    data = request.get_json()

    # make sure there are 4 numbers
    if not all(key in data for key in ("duty1", "duty2", "duty3", "duty4")):
        return jsonify({"error": "Missing one or more required numbers"}), 400

    # extract numbers and save
    try:
        x1 = float(data["duty1"])
        x2 = float(data["duty2"])
        x3 = float(data["duty3"])
        x4 = float(data["duty4"])
    except ValueError:
        return jsonify({"error": "All values must be numbers"}), 400

    PWM.setMotorModel(x1, x2, x3, x4)

    return jsonify({"status": "Successfully triggered motors"})


"""
    Endpoint for stopping all motors
"""


@app.route(rule="/stop", methods=["POST"])
def handle_request():
    PWM = Motor()

    # set all motors to 0, stops all movement
    PWM.setMotorModel(0, 0, 0, 0)

    # successful message
    return jsonify({"status": "Successfully stopped all motors"})


# Running the API
if __name__ == "__main__":
    # Setting host = "0.0.0.0" runs it on localhost
    app.run(host="0.0.0.0", port=8000, debug=True)
