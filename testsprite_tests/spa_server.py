import os
import http.server
import socketserver

PORT = 8080
DIRECTORY = "build/web"

class SPAFallingBackRequestHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def do_GET(self):
        # Check if the requested path is a physical file
        path = self.translate_path(self.path)
        # If it's a directory, check for index.html
        if os.path.isdir(path):
            index_path = os.path.join(path, "index.html")
            if not os.path.exists(index_path):
                self.path = "/index.html"
        # If the file does not exist, serve index.html
        elif not os.path.exists(path):
            self.path = "/index.html"
            
        return super().do_GET()

if __name__ == "__main__":
    # Change directory to the root of the project
    os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    # Allow port reuse
    socketserver.TCPServer.allow_reuse_address = True
    handler = SPAFallingBackRequestHandler
    with socketserver.TCPServer(("", PORT), handler) as httpd:
        print(f"Serving SPA on port {PORT}...")
        httpd.serve_forever()
