const http = require("http");
const fs = require("fs");
const path = require("path");

const HOST = "127.0.0.1";
const PORT = 3000;

const OLLAMA_HOST = "127.0.0.1";
const OLLAMA_PORT = 11434;
// Change MODEL to any Ollama model you have pulled locally,
// e.g. "llama3:8b", "mistral", "phi3", etc.
// Pull a model with: ollama pull llama3.2:3b
const MODEL = "llama3.2:3b";

const SYSTEM_PROMPT =
  "You are The OG Chatbot, an offline local AI assistant. " +
  "You must not use the internet. If you don't know something, say so.";

function readBody(req) {
  return new Promise((resolve, reject) => {
    let data = "";
    req.on("data", (chunk) => (data += chunk));
    req.on("end", () => resolve(data));
    req.on("error", reject);
  });
}

function sendJson(res, status, obj) {
  const json = JSON.stringify(obj);
  res.writeHead(status, {
    "Content-Type": "application/json; charset=utf-8",
    "Content-Length": Buffer.byteLength(json),
  });
  res.end(json);
}

function serveFile(res, filePath, contentType) {
  fs.readFile(filePath, (err, buf) => {
    if (err) {
      res.writeHead(404, { "Content-Type": "text/plain; charset=utf-8" });
      res.end("Not found");
      return;
    }
    res.writeHead(200, { "Content-Type": contentType });
    res.end(buf);
  });
}

function postToOllamaChat(payload) {
  return new Promise((resolve, reject) => {
    const body = JSON.stringify(payload);

    const req = http.request(
      {
        host: OLLAMA_HOST,
        port: OLLAMA_PORT,
        path: "/api/chat",
        method: "POST",
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          "Content-Length": Buffer.byteLength(body),
        },
      },
      (res) => {
        let data = "";
        res.on("data", (c) => (data += c));
        res.on("end", () => {
          if (res.statusCode < 200 || res.statusCode >= 300) {
            return reject(
              new Error(`Ollama error ${res.statusCode}: ${data.slice(0, 500)}`)
            );
          }
          try {
            resolve(JSON.parse(data));
          } catch (e) {
            reject(new Error("Failed to parse Ollama JSON response."));
          }
        });
      }
    );

    req.on("error", reject);
    req.write(body);
    req.end();
  });
}

const server = http.createServer(async (req, res) => {
  // Serve the UI
  if (req.method === "GET" && req.url === "/") {
    return serveFile(
      res,
      path.join(__dirname, "index.html"),
      "text/html; charset=utf-8"
    );
  }

  // Chat endpoint
  if (req.method === "POST" && req.url === "/chat") {
    try {
      const raw = await readBody(req);
      const parsed = JSON.parse(raw || "{}");

      // Expect: { messages: [{role:"user"|"assistant", content:"..."}] }
      const messages = Array.isArray(parsed.messages) ? parsed.messages : [];

      const ollamaPayload = {
        model: MODEL,
        stream: false,
        messages: [{ role: "system", content: SYSTEM_PROMPT }, ...messages],
      };

      const ollamaResp = await postToOllamaChat(ollamaPayload);
      return sendJson(res, 200, {
        reply: ollamaResp?.message?.content ?? "",
      });
    } catch (err) {
      // Expose only a short, sanitized message — never a full stack trace.
      const safeMsg =
        err && typeof err.message === "string"
          ? err.message.split("\n")[0].slice(0, 200)
          : "Internal server error";
      return sendJson(res, 500, { error: safeMsg });
    }
  }

  // Fallback 404
  res.writeHead(404, { "Content-Type": "text/plain; charset=utf-8" });
  res.end("Not found");
});

server.listen(PORT, HOST, () => {
  console.log(`The OG Chatbot UI: http://${HOST}:${PORT}`);
  console.log(
    `Make sure Ollama is running on http://${OLLAMA_HOST}:${OLLAMA_PORT}`
  );
});
