from flask import Flask, request, jsonify
import RPi.GPIO as GPIO

app = Flask(__name__)

# Define motor GPIO pins
motors = {
    'back_right': {'fwd': 8, 'bwd': 7, 'pwm': 12},
    'back_left':  {'fwd': 5, 'bwd': 6, 'pwm': 19},
    'front_right':{'fwd': 14, 'bwd': 15, 'pwm': 18},
    'front_left': {'fwd': 3, 'bwd': 2, 'pwm': 13}
}

# Setup GPIO
GPIO.setmode(GPIO.BCM)
GPIO.setwarnings(False)

for motor in motors.values():
    GPIO.setup(motor['fwd'], GPIO.OUT)
    GPIO.setup(motor['bwd'], GPIO.OUT)
    GPIO.setup(motor['pwm'], GPIO.OUT)
    motor['pwm_obj'] = GPIO.PWM(motor['pwm'], 100)
    motor['pwm_obj'].start(0)

# Control functions
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

def move_forward():   [set_motor(m, 'fwd') for m in motors]
def move_backward():  [set_motor(m, 'bwd') for m in motors]
def move_left():
    set_motor('front_left', 'bwd')
    set_motor('front_right', 'fwd')
    set_motor('back_left', 'fwd')
    set_motor('back_right', 'bwd')
def move_right():
    set_motor('front_left', 'fwd')
    set_motor('front_right', 'bwd')
    set_motor('back_left', 'bwd')
    set_motor('back_right', 'fwd')
def stop():           [set_motor(m, 'stop') for m in motors]

# API route
@app.route('/move', methods=['POST'])
def move():
    data = request.get_json()
    command = data.get('command', '').lower()

    if command == 'forward':
        move_forward()
    elif command == 'backward':
        move_backward()
    elif command == 'left':
        move_left()
    elif command == 'right':
        move_right()
    elif command == 'stop':
        stop()
    else:
        stop()
        return jsonify({'status': 'error', 'message': 'Unknown command'}), 400

    return jsonify({'status': 'ok', 'command': command})

# Cleanup on shutdown
@app.route('/shutdown', methods=['POST'])
def shutdown():
    stop()
    GPIO.cleanup()
    return jsonify({'status': 'GPIO cleaned up and server ready to shut down'})

if __name__ == '__main__':
    try:
        app.run(host='0.0.0.0', port=8000)
    finally:
        stop()
        GPIO.cleanup()