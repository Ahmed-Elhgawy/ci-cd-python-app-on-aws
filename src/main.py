from flask import Flask

app = Flask(__name__)

@app.route('/')
def hello_word():
  return "<h1>Hello World</h1><br><p>I hope you enjoyed it, follow for more content around Devops.</p>"

if __name__ == "__main__":
  app.run(debug=True, host='0.0.0.0')