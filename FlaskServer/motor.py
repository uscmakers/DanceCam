import RPi.GPIO as GPIO
from RpiMotorLib import RpiMotorLib
import time

#define GPIO pins
direction = 26 # Direction (DIR) GPIO Pin
step = 20 # Step GPIO Pin
EN_pin = 21 # enable pin (LOW to enable)

#define GPIO pins
magnet1 = 25 #  GPIO Pin for magnet 1
magnet2 = 6 #  GPIO pin for magnet 2
magnet3 = 5 #  GPIO pin for magnet 3
magnet4 = 17 #  GPIO pin for magnet 4

#define map from player number to magent GPIO pins
magnets = [magnet1, magnet2, magnet3, magnet4]

# Declare a instance of class pass GPIO pins numbers and the motor type
GPIO.setmode(GPIO.BCM)
# GPIO.setup(magnet1,GPIO.OUT) # set enable pin as output for magnet 1
# GPIO.setup(magnet2,GPIO.OUT) # set enable pin as output for magnet 2

# Declare a instance of class pass GPIO pins numbers and the motor type
mymotortest = RpiMotorLib.A4988Nema(direction, step, (21,21,21), "DRV8825")
# GPIO.setup(EN_pin,GPIO.OUT) # set enable pin as output

def turnMotor(numSteps: int, clockwise: bool):
    GPIO.setmode(GPIO.BCM)
    GPIO.setup(EN_pin,GPIO.OUT) # set enable pin as output
    GPIO.output(EN_pin,GPIO.LOW) # pull enable to low to enable motor
    mymotortest.motor_go(clockwise, # True=Clockwise, False=Counter-Clockwise
                     "Full" , # Step type (Full,Half,1/4,1/8,1/16,1/32)
                     numSteps, # number of steps
                     .02, # step delay [sec]
                     False, # True = print verbose output 
                     .05) # initial delay [sec]
    GPIO.cleanup()
    
def electromagnetOn(num: int):
    print("[ELECTROMAGNET] Turning electromagnet", num, "on!")
    GPIO.setmode(GPIO.BCM)
    GPIO.setup(magnets[num],GPIO.OUT) # set enable pin as output
    GPIO.output(magnets[num], GPIO.LOW)

def electromagnetOff(num: int):
    print("[ELECTROMAGNET] Turning electromagnet", num, "off!")
    GPIO.setmode(GPIO.BCM)
    GPIO.setup(magnets[num],GPIO.OUT) # set enable pin as output
    GPIO.output(magnets[num], GPIO.HIGH)
    GPIO.cleanup()