import curses
from gpiozero import Motor, PWMOutputDevice


class Vehicle:
    def __init__(self):
        self.back_left_motor = Motor(forward=7, backward=8)
        self.back_left_pwm = PWMOutputDevice(12)
        self.back_left_pwm.value = 0

        self.back_right_motor = Motor(forward=6, backward=5)
        self.back_right_pwm = PWMOutputDevice(13)
        self.back_right_pwm.value = 0

        self.front_left_motor = Motor(forward=3, backward=2)
        self.front_left_pwm = PWMOutputDevice(19)
        self.front_left_pwm.value = 0

        self.front_right_motor = Motor(forward=14, backward=15)
        self.front_right_pwm = PWMOutputDevice(18)
        self.front_right_pwm.value = 0
    def forward(self):
        self.back_left_motor.forward()
        self.back_left_pwm.value = 1

        self.back_right_motor.forward()
        self.back_right_pwm.value = 1

        self.front_left_motor.forward()
        self.front_left_pwm.value = 1

        self.front_right_motor.forward()
        self.front_right_pwm.value = 1
    def backward(self):
        self.back_left_motor.backward()
        self.back_left_pwm.value = 1

        self.back_right_motor.backward()
        self.back_right_pwm.value = 1

        self.front_left_motor.backward()
        self.front_left_pwm.value = 1

        self.front_right_motor.backward()
        self.front_right_pwm.value = 1
    def left(self):
        self.back_left_motor.forward()
        self.back_left_pwm.value = 1

        self.back_right_motor.backward()
        self.back_right_pwm.value = 1

        self.front_left_motor.backward()
        self.front_left_pwm.value = 1

        self.front_right_motor.forward()
        self.front_right_pwm.value = 1
    def right(self):
        self.back_left_motor.backward()
        self.back_left_pwm.value = 1

        self.back_right_motor.forward()
        self.back_right_pwm.value = 1

        self.front_left_motor.forward()
        self.front_left_pwm.value = 1

        self.front_right_motor.backward()
        self.front_right_pwm.value = 1
    def map_key_to_command(self, key):
        map = {
            curses.KEY_UP: self.forward,
            curses.KEY_DOWN: self.backward,
            curses.KEY_LEFT: self.left,
            curses.KEY_RIGHT: self.right,
        }
        return map[key]

    def control(self, key):
        return self.map_key_to_command(key)


rpi_vehicle = Vehicle()


def main(window):
    next_key = None

    while True:
        curses.halfdelay(1)
        if next_key is None:
            key = window.getch()
            print(key)
        else:
            key = next_key
            next_key = None
        if key != -1:
            # KEY PRESSED
            curses.halfdelay(1)
            action = rpi_vehicle.control(key)
            if action:
                action()
            next_key = key
            while next_key == key:
                next_key = window.getch()
            # KEY RELEASED
            rpi_vehicle.back_left_motor.stop()
            rpi_vehicle.back_right_motor.stop()
            rpi_vehicle.front_left_motor.stop()
            rpi_vehicle.front_right_motor.stop()

curses.wrapper(main)
