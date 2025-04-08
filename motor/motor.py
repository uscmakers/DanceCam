import RPi.GPIO as GPIO
import time

# Define motor GPIO pins
motors = {
    'back_right': {'fwd': 8, 'bwd': 7, 'pwm': 12},
    'back_left':  {'fwd': 5, 'bwd': 6, 'pwm': 19},
    'front_right':{'fwd': 14, 'bwd': 15, 'pwm': 18},
    'front_left': {'fwd': 3, 'bwd': 2, 'pwm': 13}
}

GPIO.setmode(GPIO.BCM)
GPIO.setwarnings(False)

# Setup pins
for motor in motors.values():
    GPIO.setup(motor['fwd'], GPIO.OUT)
    GPIO.setup(motor['bwd'], GPIO.OUT)
    GPIO.setup(motor['pwm'], GPIO.OUT)
    motor['pwm_obj'] = GPIO.PWM(motor['pwm'], 100)
    motor['pwm_obj'].start(0)

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

def move_forward():
    for m in motors: set_motor(m, 'fwd')

def move_backward():
    for m in motors: set_motor(m, 'bwd')

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

def stop():
    for m in motors: set_motor(m, 'stop')

# Main loop
try:
    while True:
        print("\nEnter command:")
        print("[w] forward  [s] backward  [a] left  [d] right  [x] stop  [q] quit")
        cmd = input("Command: ").lower()
        if cmd == 'w':
            move_forward()
        elif cmd == 's':
            move_backward()
        elif cmd == 'a':
            move_left()
        elif cmd == 'd':
            move_right()
        elif cmd == 'x':
            stop()
        elif cmd == 'q':
            break
        else:
            stop()

except KeyboardInterrupt:
    print("Interrupted")

finally:
    stop()
    GPIO.cleanup()
    print("GPIO cleaned up. Exiting.")
