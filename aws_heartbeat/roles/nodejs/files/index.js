const http = require("http")

http.createServer(function (request, response) {
  response.writeHead(200, { 'Content-Type': 'text/plain' });
  response.end('Hello World!\n');
}).listen(80);

console.log("Hello World HTTP server ready on port 80.")