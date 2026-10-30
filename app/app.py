from http.server import BaseHTTPRequestHandler, HTTPServer
import socket
import os
import time

HOST = "127.0.0.1"
PORT = 8080


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/":
            body = (
                    "support-app is running\n"
                    f"hostname={socket.gethostname()}\n"
                    f"pid={os.getpid()}\n"
            )
                    
            self.send_response(200)
            self.send_header("Content-Type", "text/plain; charset=utf-8")
            self.send_header("Content-Length", str(len(body.encode())))
            self.end_headers()
            self.wfile.write(body.encode())
        else:
            self.send_response(404)
            self.end_headers()


server = HTTPServer((HOST, PORT), Handler)

print(f"Listening on {HOST}:{PORT}", flush=True)
server.serve_forever()
