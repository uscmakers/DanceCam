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
    