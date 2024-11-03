# Importing required packages
from flask import Flask, request, jsonify

# Initiating a Flask application
app = Flask(__name__)

# The endpoint of our flask app
@app.route(rule="/", methods=["GET", "POST"])
def handle_request():
    # The GET endpoint
    if request.method == "GET":
        return "This is the GET Endpoint of flask API."
    
    # The POST endpoint
    if request.method == "POST":
        # accesing the passed payload
        payload = request.get_json()
        # capitalizing the text
        cap_text = payload['text'].upper()
        # Creating a proper response
        response = {'cap-text': cap_text}
        # return the response as JSON
        return jsonify(response)

# Running the API
if __name__ == "__main__":
    # Setting host = "0.0.0.0" runs it on localhost
    app.run(host="0.0.0.0", debug=True)