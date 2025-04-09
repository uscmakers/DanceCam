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

current_motor_speeds = {
    'front_right':0,
    'front_left':0,
    'back_left':0,
    'back_right':0,
}

def set_motors(motor_speeds):
    for motor, direction, speed in motor_speeds:
        if speed != current_motor_speeds[motor]:
            print(motor, direction, speed)
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
            pwm.ChangeDutyCycle(abs(speed))
            current_motor_speeds[motor] = speed

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
    motor_speeds = [
        ('front_right', 'fwd' if duty1 > 0 else 'bwd', 100),
        ('front_left', 'fwd' if duty2 > 0 else 'bwd', 100),
        ('back_left', 'fwd' if duty3 > 0 else 'bwd', 100),
        ('back_right', 'fwd' if duty4 > 0 else 'bwd', 100),
    ]
    set_motors(motor_speeds)
    return jsonify({"status": "Successfully triggered motors"})

"""
    Endpoint for stopping all motors
"""

@app.route(rule="/stop", methods=["POST"])
def handle_stop_request():
    motor_speeds = [
        ('front_right', 'stop', 0),
        ('front_left', 'stop', 0),
        ('back_left', 'stop', 0),
        ('back_right', 'stop', 0),
    ]
    set_motors(motor_speeds)    
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