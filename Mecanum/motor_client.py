import asyncio
import websockets
import json
import logging
from dotenv import load_dotenv
import os
from Motor import *

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

load_dotenv()

class RobotClient:
    def __init__(self, uri):
        self.uri = uri
        self.websocket = None
        self.paired_with = None
        self.PWM = Motor()

    async def connect(self):
        try:
            self.websocket = await websockets.connect(f"{self.uri}?clientType=robot")
            logger.info("Connected to WebSocket server")
            return True
        except Exception as e:
            logger.error(f"Failed to connect: {e}")
            return False

    async def handle_message(self, message):
        try:
            data = json.loads(message)
            message_type = data.get('type')
            
            if message_type == 'host_pairConnect':
                self.paired_with = data['data']
                logger.info(f"Paired with user: {self.paired_with}")

                await self.send_message("Hello! I'm your robot assistant.")
                
            elif message_type == 'host_pairDisconnect':
                logger.info("User disconnected")
                self.paired_with = None
                
            elif message_type == 'client_message':
                if self.paired_with:
                    user_message = data['data'].get('data', {})
                    logger.info(f"Received message from user: {user_message}")

                    if data['type'] == 'move':
                        duty1 = data['duty1']
                        duty2 = data['duty2']
                        duty3 = data['duty3']
                        duty4 = data['duty4']
                        PWM.setMotorModel(duty1, duty2, duty3, duty4)
                    elif data['type'] == 'stop':
                        PWM.setMotorModel(0, 0, 0, 0)
            
            else:
                logger.warning(f"Unknown message type: {message_type}")
                
        except json.JSONDecodeError:
            logger.error("Failed to parse message as JSON")
        except Exception as e:
            logger.error(f"Error handling message: {e}")

    async def send_message(self, content):
        if not self.websocket:
            logger.error("Not connected to server")
            return
            
        try:
            message = {
                "type": "client_message",
                "data": content
            }
            await self.websocket.send(json.dumps(message))
            logger.info(f"Sent message: {content}")
        except Exception as e:
            logger.error(f"Failed to send message: {e}")

    async def run(self):
        while True:
            try:
                if not self.websocket:
                    success = await self.connect()
                    if not success:
                        await asyncio.sleep(5)  # Wait before retrying
                        continue

                async for message in self.websocket:
                    await self.handle_message(message)
                    
            except websockets.exceptions.ConnectionClosed:
                logger.warning("Connection closed, attempting to reconnect...")
                self.websocket = None
                self.paired_with = None
                await asyncio.sleep(5)  # Wait before retrying
                
            except Exception as e:
                logger.error(f"Unexpected error: {e}")
                self.websocket = None
                self.paired_with = None
                await asyncio.sleep(5)  # Wait before retrying

async def main():
    robot = RobotClient(os.getenv("CONNECTION_URL"))
    await robot.run()

if __name__ == "__main__":
    asyncio.run(main())