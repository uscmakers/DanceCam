from flask import Flask, request, jsonify

app = Flask(__name__)

# route to get data 
@app.route('/api/data', methods=['GET'])
def get_data():
    # dummy response
    return jsonify({"status": "success", "data": "Hello from Raspberry Pi"})

# route to retrieve data 
@app.route('/api/data', methods=['POST'])
def receive_data():
    data = request.json
    # process received data here
    return jsonify({"status": "received"})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000) # ip address and port 