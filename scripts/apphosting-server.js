const http = require("http");
const fs = require("fs");
const path = require("path");

const port = Number(process.env.PORT || 8080);
const host = process.env.HOST || "0.0.0.0";
const rootDir = path.resolve(__dirname, "..", "packages", "web", "dist");

const mimeTypes = {
  ".html": "text/html; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".js": "application/javascript; charset=utf-8",
  ".mjs": "application/javascript; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".svg": "image/svg+xml",
  ".png": "image/png",
  ".jpg": "image/jpeg",
  ".jpeg": "image/jpeg",
  ".ico": "image/x-icon",
  ".webp": "image/webp",
  ".woff": "font/woff",
  ".woff2": "font/woff2",
};

function resolveFile(urlPath) {
  const clean = decodeURIComponent((urlPath || "/").split("?")[0]);
  const requested = clean === "/" ? "/index.html" : clean;
  const safePath = path.normalize(requested).replace(/^([.][.][/\\])+/, "");
  return path.join(rootDir, safePath);
}

const server = http.createServer((req, res) => {
  const filePath = resolveFile(req.url || "/");

  fs.readFile(filePath, (err, data) => {
    if (!err) {
      const ext = path.extname(filePath).toLowerCase();
      res.writeHead(200, { "Content-Type": mimeTypes[ext] || "application/octet-stream" });
      res.end(data);
      return;
    }

    fs.readFile(path.join(rootDir, "index.html"), (fallbackErr, fallbackData) => {
      if (fallbackErr) {
        res.writeHead(500, { "Content-Type": "text/plain; charset=utf-8" });
        res.end("Build output not found. Run npm run build before start.");
        return;
      }
      res.writeHead(200, { "Content-Type": "text/html; charset=utf-8" });
      res.end(fallbackData);
    });
  });
});

server.listen(port, host, () => {
  console.log(`Modulo Squares server running at http://${host}:${port}`);
});
