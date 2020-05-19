import io
from flask import Flask, request, make_response

app = Flask(__name__)

txt_paths = ['src-train', 'src-val', 'tgt-train', 'tgt-val']
html_paths = ['monitor-d4j', 'monitor-codrep', 'monitor-codrep-pilot-1']
csv_paths = ['data-d4j', 'data-codrep', 'data-codrep-pilot-1']

def get_file(filename):
    fo = io.open(filename, 'r', encoding='utf-8')
    content = fo.read()
    fo.close()
    return content

@app.route('/<string:path>', methods=['GET'])
def handle_get(path):
    response_code = 200
    response_text = ''
    mimetype = 'text/plain'

    if(path in txt_paths):
        response_text = get_file(f'{path}.txt')
    elif(path in html_paths):
        response_text = get_file(f'{path}.html')
        mimetype = 'text/html'
    elif(path in csv_paths):
        response_text = get_file(f'{path}.csv')
    else:
        response_code = 400
        response_text = 'bad request'
    
    response = make_response(response_text, response_code)
    response.mimetype = mimetype

    return response

@app.route('/<string:path>', methods=['POST'])
def handle_post(path):
    body = request.get_data()
    
    response_code = 200
    response_text = ""

    if(path in csv_paths):
        data_file = io.open(f"{path}.csv", "a", encoding="utf-8")
        data_file.write(body.decode('utf-8') + '\n')
        data_file.close()

        response_text = 'OK'
        response_code = 200
    else:
        response_text = 'bad request'
        response_code = 400

    return make_response(response_text, response_code)
