import io
from http.server import HTTPServer, BaseHTTPRequestHandler

class SimpleHTTPRequestHandler(BaseHTTPRequestHandler):

    txt_paths = ['/src-train', '/src-val', '/tgt-train', '/tgt-val']
    html_paths = ['/monitor-d4j', '/monitor-codrep']
    csv_paths = ['/data-df4', '/data-codrep']

    def do_GET(self):
        response_code = 200
        response = ""

        if(self.path in self.txt_paths):
            fo = io.open(f"{self.path[1:]}.txt", 'r', encoding='utf-8')
            content = fo.read()
            response = content.encode('utf-8')
            fo.close()
        elif(self.path in self.html_paths):
            fo = io.open(f"{self.path[1:]}.html", 'r', encoding='utf-8')
            content = fo.read()
            response = content.encode('utf-8')
            fo.close()
        elif(self.path in self.csv_paths):
            fo = io.open(f"{self.path[1:]}.csv", 'r', encoding='utf-8')
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

        if(self.path in csv_paths):
            data_file = io.open(f"{self.path[1:]}.csv", "a", encoding="utf-8")
            data_file.write(body.decode('utf-8') + '\n')
            data_file.close()

            self.send_response(200)
            self.end_headers()
            self.wfile.write(b'OK')
        else:
            self.send_response(400)
            self.end_headers()
            self.wfile.write(b'bad request')

httpd = HTTPServer(('', 8080), SimpleHTTPRequestHandler)
httpd.serve_forever()
