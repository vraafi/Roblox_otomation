import http.server
import socketserver
import json
from datetime import datetime

PORT = 5000
LOG_FILE = "telemetry_logs.txt"

class TelemetryHandler(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        if self.path == '/telemetry':
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)

            try:
                data = json.loads(post_data.decode('utf-8'))

                log_entry = f"[{datetime.now().isoformat()}] {data.get('type', 'UNKNOWN')}: {data.get('message', '')}"

                if 'details' in data:
                    log_entry += f" | Details: {json.dumps(data['details'])}"

                print(log_entry)

                with open(LOG_FILE, "a") as f:
                    f.write(log_entry + "\n")

                self.send_response(200)
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                self.wfile.write(b'{"status": "success"}')
            except Exception as e:
                self.send_response(400)
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                self.wfile.write(b'{"status": "error", "message": "Invalid JSON payload"}')
        else:
            self.send_response(404)
            self.end_headers()

with socketserver.TCPServer(("", PORT), TelemetryHandler) as httpd:
    print(f"Telemetry server listening on port {PORT}")
    httpd.serve_forever()
