import RPi.GPIO as GPIO
from flask import Flask, request, jsonify

# Initiating a Flask application
app = Flask(__name__)

# Define motor GPIO pins
motors = {
    'front_right':{'fwd': 14, 'bwd': 15, 'pwm': 18},
    'front_left':{'fwd': 3, 'bwd': 2, 'pwm': 13},
    'back_left':{'fwd': 5, 'bwd': 6, 'pwm': 19}, 
    'back_right':{'fwd': 8, 'bwd': 7, 'pwm': 12},
}

# Set motor forward enable, backward enable, and PWM pins
def set_motor(motor, direction, speed=100):
    fwd = motors[motor]['fwd']
    bwd = motors[motor]['bwd']
    pwm = motors[motor]['pwm_obj']
    if direction == 'fwd':
        GPIO.output(fwd, GPIO.HIGH)
        GPIO.output(bwd, GPIO.LOW)
    elif direction == 'bwd':
        GPIO.output(fwd, GPIO.LOW)
        GPIO.output(bwd, GPIO.HIGH)
    else:
        GPIO.output(fwd, GPIO.LOW)
        GPIO.output(bwd, GPIO.LOW)
        speed = 0
    pwm.ChangeDutyCycle(speed)

"""
    Endpoint for sending signal to motors
"""

@app.route(rule="/move", methods=["POST"])
def handle_move_request():
    data = request.get_json()
    try:
        duty1 = data['duty1'] # front_right
        duty2 = data['duty2'] # front_left
        duty3 = data['duty3'] # back_right
        duty4 = data['duty4'] # back_left
    except ValueError:
        return jsonify({"error": "All values must be numbers"}), 400

    if duty1 > 0: set_motor('front_right', 'fwd', duty1)
    else: set_motor('front_right', 'bwd', duty1)
    if duty2 > 0: set_motor('front_left', 'fwd', duty2)
    else: set_motor('front_left', 'bwd', duty2)
    if duty3 > 0: set_motor('back_left', 'fwd', duty3)
    else: set_motor('back_left', 'bwd', duty3)
    if duty4 > 0: set_motor('back_right', 'fwd', duty4)
    else: set_motor('back_right', 'bwd', duty4)

    return jsonify({"status": "Successfully triggered motors"})

"""
    Endpoint for stopping all motors
"""

@app.route(rule="/stop", methods=["POST"])
def handle_stop_request():
    for motor in motors: set_motor(motor, 'stop')
    
    return jsonify({"status": "Successfully stopped all motors"})

# Running the API
if __name__ == "__main__":
    GPIO.setmode(GPIO.BCM)
    GPIO.setwarnings(False)
    
    # Setup pins
    for motor in motors.values():
        GPIO.setup(motor['fwd'], GPIO.OUT)
        GPIO.setup(motor['bwd'], GPIO.OUT)
        GPIO.setup(motor['pwm'], GPIO.OUT)
        motor['pwm_obj'] = GPIO.PWM(motor['pwm'], 100)
        motor['pwm_obj'].start(0)
    
    # Setting host = "0.0.0.0" runs it on localhost
    app.run(host="0.0.0.0", port=8000, debug=True)