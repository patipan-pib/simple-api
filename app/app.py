
from flask import Flask, jsonify

app = Flask(__name__)

GETCODE = "SUCCESS"

@app.route('/')
def index():
    return "Index!"


@app.route('/getcode', methods=['GET'])
def getcode():
    return jsonify({ 'code': GETCODE })

@app.route('/plus/<num1>/<num2>', methods=['GET'])
def plus(num1, num2):
    try:
        num1 = eval(num1)
        num2 = int(num2)
        result = { 'result' : num1 + num2 }
    except:
        result = { 'error_msg' : 'inputs must be numbers' }

    return jsonify(result)



if __name__ == '__main__':
    app.run()
