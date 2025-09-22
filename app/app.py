
from flask import Flask, jsonify

app = Flask(__name__)

GETCODE = "TEST SUCCESS"

@app.route('/')
def index():
    return "Index!"

@app.route('/hello/<name>', methods=['GET'])
def hello(name):
    return "Hello, " + str(name)

@app.route('/getcode', methods=['GET'])
def getcode():
    return GETCODE

@app.route('/plus/<num1>/<num2>', methods=['GET'])
def plus(num1, num2):
    try:
        num1 = eval(num1)
        num2 = int(num2)
        result = { 'result' : num1 + num2 }
    except:
        result = { 'error_msg' : 'inputs must be numbers' }

    return jsonify(result)


@app.route('/calculate/<num1>/<num2>', methods=['GET'])
def calculate(num1, num2):
    try:
        num1 = eval(num1)
        num2 = int(num2)

        results = {
                'plus' : num1 + num2,
                'minus' : num1 - num2,
                'multiply': num1 * num2,
                'divide' : num1/num2
            }
    except:
        results = { 'error_msg' : 'inputs must be numbers' }

    return jsonify(results)


if __name__ == '__main__':
    app.run()
