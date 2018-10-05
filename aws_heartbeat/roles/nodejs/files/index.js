const http = require("http")

http.createServer(function (request, response) {

    const content = `
    <html>
      <head>
        <title>Hello World</title>
      </head>
      <body>
        <h1>Hello World!</h1>
      </body>
    </html>`;

    response.writeHead(200, {'Content-Type': 'text/html'});

    response.end(content+'\n');
}).listen(80);