import io
from http.server import HTTPServer, BaseHTTPRequestHandler


src_train_path = "src-train.txt"
src_val_path = "src-val.txt"
tgt_train_path = "tgt-train.txt"
tgt_val_path = "tgt-val.txt"


class SimpleHTTPRequestHandler(BaseHTTPRequestHandler):

    def do_GET(self):
        response_code = 200
        response = ""

        if(self.path == '/src-train' or self.path == '/src-val' or 
           self.path == '/tgt-train' or self.path == '/tgt-val'):
            fo = io.open(f"{self.path[1:]}.txt", 'r', encoding='utf-8')
            content = fo.read()
            response = content.encode('utf-8')
            fo.close()
        elif(self.path == '/monitor'):
            fo = io.open(f"{self.path[1:]}.html", 'r', encoding='utf-8')
            content = fo.read()
            response = content.encode('utf-8')
            fo.close()
        elif(self.path == '/data.csv'):
            fo = io.open(f"{self.path[1:]}", 'r', encoding='utf-8')
            content = fo.read()
            response = content.encode('utf-8')
            fo.close()
        else:
            response_code = 400
            response = b'bad request'

        self.send_response(response_code)
        self.end_headers()
        self.wfile.write(response)



    def do_POST(self):
        content_length = int(self.headers['Content-Length'])
        body = self.rfile.read(content_length)

        if(self.path == '/data'):
            data_file = io.open("data.csv", "a", encoding="utf-8")
            data_file.write(body.decode('utf-8') + '\n')

            self.send_response(200)
            self.end_headers()
            self.wfile.write(b'OK')

        else:
            self.send_response(400)
            self.end_headers()
            self.wfile.write(b'bad request')

httpd = HTTPServer(('', 8080), SimpleHTTPRequestHandler)
httpd.serve_forever()
