import asyncio
from dotenv import load_dotenv
import os
from Motor import *
from robotClient import RobotClient

load_dotenv()
PWM = Motor()

def on_move(duty1, duty2, duty3, duty4):
    PWM.setMotorModel(duty1, duty2, duty3, duty4)

def on_stop():
    PWM.setMotorModel(0, 0, 0, 0)

async def main():
    robot = RobotClient(os.getenv("CONNECTION_URL"), on_move, on_stop)
    await robot.run()

if __name__ == "__main__":
    asyncio.run(main())