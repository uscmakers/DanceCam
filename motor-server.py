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
def set_motor(motor, direction, speed):
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

def move_forward(speed):
    for m in motors: set_motor(m, 'fwd', speed)
def move_backward(speed):
    for m in motors: set_motor(m, 'bwd', speed)
def move_left(speed):
    set_motor('front_left', 'bwd', speed)
    set_motor('front_right', 'fwd', speed)
    set_motor('back_left', 'fwd', speed)
    set_motor('back_right', 'bwd', speed)
def move_right(speed):
    set_motor('front_left', 'fwd', speed)
    set_motor('front_right', 'bwd', speed)
    set_motor('back_left', 'bwd', speed)
    set_motor('back_right', 'fwd', speed)
def move_backward_left(speed):
    set_motor('front_left', 'bwd', speed)
    set_motor('front_right', 'stop', 0)
    set_motor('back_left', 'stop', 0)
    set_motor('back_right', 'bwd', speed)
def move_backward_right(speed):
    set_motor('front_left', 'stop', 0)
    set_motor('front_right', 'bwd', speed)
    set_motor('back_left', 'bwd', speed)
    set_motor('back_right', 'stop', 0)
def move_forward_left(speed):
    set_motor('front_left', 'stop', 0)
    set_motor('front_right', 'fwd', speed)
    set_motor('back_left', 'fwd', speed)
    set_motor('back_right', 'stop', 0)
def move_forward_right(speed):
    set_motor('front_left', 'fwd', speed)
    set_motor('front_right', 'stop', 0)
    set_motor('back_left', 'stop', 0)
    set_motor('back_right', 'fwd', speed)
def stop():           
    for m in motors: set_motor(m, 'stop', 0)

# API route
@app.route('/move', methods=['POST'])
def move():
    data = request.get_json()
    command = data['command']
    speed = data['speed']
    print(speed, command)
    if command == 'forward':
        move_forward(speed)
    elif command == 'backward':
        move_backward(speed)
    elif command == 'left':
        move_left(speed)
    elif command == 'right':
        move_right(speed)
    elif command == 'backward left':
        move_backward_left(speed)
    elif command == 'backward right':
        move_backward_right(speed)
    elif command == 'forward left':
        move_forward_left(speed)
    elif command == 'forward right':
        move_forward_right(speed)
    elif command == 'stop':
        stop()
    
    else:
        stop()
        return jsonify({'status': 'error', 'message': 'Unknown command'}), 400
    return jsonify({'status': 'ok', 'command': command, 'speed': speed})

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