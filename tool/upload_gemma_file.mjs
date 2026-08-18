import fs from "node:fs";
import https from "node:https";
import { createRequire } from "node:module";
import path from "node:path";

const require = createRequire(import.meta.url);
const toolsRoot = path.join(
  process.env.APPDATA,
  "npm/node_modules/firebase-tools/lib",
);
const { configstore } = require(path.join(toolsRoot, "configstore.js"));
const auth = require(path.join(toolsRoot, "auth.js"));

const filePath = process.argv[2];
const objectName = process.argv[3] ?? path.posix.join("gemma", path.basename(filePath));
const bucket = "notis-2dee0.firebasestorage.app";
const chunkSize = 8 * 1024 * 1024;

if (!filePath || !fs.existsSync(filePath)) {
  console.error("Usage: node upload_gemma_file.mjs <local-file> [object-name]");
  process.exit(1);
}

const stat = fs.statSync(filePath);
const tokens = configstore.get("tokens");
if (!tokens?.refresh_token) {
  console.error("firebase login first");
  process.exit(1);
}

const creds = await auth.getAccessToken(tokens.refresh_token, tokens.scopes || []);
const access = creds.access_token;
if (!access) {
  console.error("Could not refresh Firebase access token");
  process.exit(1);
}

function request(url, options, body) {
  return new Promise((resolve, reject) => {
    const dest = new URL(url);
    const req = https.request(
      dest,
      { method: options.method ?? "GET", headers: options.headers ?? {} },
      (res) => {
        const chunks = [];
        res.on("data", (c) => chunks.push(c));
        res.on("end", () => {
          resolve({
            status: res.statusCode ?? 0,
            headers: res.headers,
            body: Buffer.concat(chunks).toString("utf8"),
          });
        });
      },
    );
    req.on("error", reject);
    if (body) req.end(body);
    else req.end();
  });
}

const start = await request(
  `https://storage.googleapis.com/upload/storage/v1/b/${bucket}/o` +
    `?uploadType=resumable&name=${encodeURIComponent(objectName)}`,
  {
    method: "POST",
    headers: {
      Authorization: `Bearer ${access}`,
      "Content-Type": "application/json; charset=UTF-8",
      "X-Upload-Content-Type": "application/octet-stream",
      "X-Upload-Content-Length": String(stat.size),
    },
  },
  JSON.stringify({
    name: objectName,
    contentType: "application/octet-stream",
  }),
);

if (start.status !== 200 && start.status !== 201) {
  throw new Error(`Start upload failed: ${start.status} ${start.body.slice(0, 400)}`);
}
const sessionUrl = start.headers.location;
if (!sessionUrl) throw new Error("No resumable session URL");

console.log(`Uploading ${(stat.size / 1e6).toFixed(1)} MB → gs://${bucket}/${objectName}`);

const fd = fs.openSync(filePath, "r");
let offset = 0;
try {
  while (offset < stat.size) {
    const end = Math.min(offset + chunkSize, stat.size);
    const buf = Buffer.alloc(end - offset);
    fs.readSync(fd, buf, 0, buf.length, offset);
    const res = await request(sessionUrl, {
      method: "PUT",
      headers: {
        "Content-Length": String(buf.length),
        "Content-Range": `bytes ${offset}-${end - 1}/${stat.size}`,
        "Content-Type": "application/octet-stream",
      },
    }, buf);
    const ok =
      res.status === 308 ||
      res.status === 200 ||
      res.status === 201;
    if (!ok) {
      throw new Error(`Chunk ${offset}-${end - 1} failed: ${res.status} ${res.body.slice(0, 300)}`);
    }
    offset = end;
    const pct = ((offset / stat.size) * 100).toFixed(1);
    console.log(`${pct}% (${(offset / 1e6).toFixed(1)} / ${(stat.size / 1e6).toFixed(1)} MB)`);
  }
} finally {
  fs.closeSync(fd);
}

console.log("Upload complete.");
