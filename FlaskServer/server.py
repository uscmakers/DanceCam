from flask import Flask, request, jsonify

app = Flask(__name__)

# route to get data 
@app.route('/', methods=['GET'])
def get_data():
    # dummy response
    return jsonify({"status": "success", "data": "Hello from Raspberry Pi"})


# route to retrieve data
@app.route("/api/post", methods=["POST"])
def receive_data():
    data = request.json
    # process received data here
    print("Received data!")
    print(data)
    return jsonify({"status": "received"})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000) # ip address and port 
    
    
    from flask import Flask, request, jsonify
import pathlib
import json
import time

# Define Flask server
app = Flask(__name__)
thisdir = pathlib.Path(__file__).parent.absolute() # path to directory of this file

# Function to process the json data received by the server
def process_json(data):
    data = json.loads(data) # convert json string to json object dictionary
    #TODO figure out fields from JSON request
    # Parse data from JSON (TBD what field to be accepeted?)
    speed = data['speed'] 
    direction = data['direction']
    delta_pos = data['delta_pos']
    print(f"Direction: {direction} | delta_pos {delta_pos}")
    
    #Move motors and use data 
    
# Move motor route
@app.route('/move', methods=['POST'])
def move_one():
    try:
        received = request.get_json()
        process_json(received)
        res = jsonify({})
        res.status_code = 201 # Status code for "created"
        return res
    except Exception as e:
        res = jsonify({"Error": e})
        res.status_code = 501

if __name__ == '__main__':
    app.run(host='172.20.10.4', port=4444)
