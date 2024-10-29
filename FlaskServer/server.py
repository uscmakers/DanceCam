from flask import Flask, request, jsonify
import pathlib

# Define Flask server
app = Flask(__name__)
thisdir = pathlib.Path(__file__).parent.absolute() # path to directory of this file

# Move motor route
@app.route('/move', methods=['POST'])
def move_one():
    res = jsonify({})
    res.status_code = 201 # Status code for "created"
    return res

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=4444)