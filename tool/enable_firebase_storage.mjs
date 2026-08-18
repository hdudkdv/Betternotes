import { createRequire } from "node:module";
import path from "node:path";

const require = createRequire(import.meta.url);
const toolsRoot = path.join(
  process.env.APPDATA,
  "npm/node_modules/firebase-tools/lib",
);
const { configstore } = require(path.join(toolsRoot, "configstore.js"));
const auth = require(path.join(toolsRoot, "auth.js"));

const tokens = configstore.get("tokens");
const creds = await auth.getAccessToken(tokens.refresh_token, tokens.scopes || []);
const access = creds.access_token;
const project = "notis-2dee0";

async function call(method, url, body) {
  const res = await fetch(url, {
    method,
    headers: {
      Authorization: `Bearer ${access}`,
      "Content-Type": "application/json",
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await res.text();
  return { status: res.status, text };
}

const enable = await call(
  "POST",
  `https://serviceusage.googleapis.com/v1/projects/${project}/services/firebasestorage.googleapis.com:enable`,
);
console.log("enable API", enable.status, enable.text.slice(0, 300));

const create = await call(
  "POST",
  `https://storage.googleapis.com/storage/v1/b?project=${project}`,
  {
    name: `${project}.firebasestorage.app`,
    location: "EUROPE-WEST3",
    storageClass: "STANDARD",
    iamConfiguration: { uniformBucketLevelAccess: { enabled: true } },
  },
);
console.log("create bucket", create.status, create.text.slice(0, 500));

const bucket = await call(
  "POST",
  `https://firebasestorage.googleapis.com/v1beta/projects/${project}/defaultBucket`,
  { location: "EUROPE-WEST3" },
);
console.log("defaultBucket", bucket.status, bucket.text.slice(0, 500));

const get = await call(
  "GET",
  `https://storage.googleapis.com/storage/v1/b/${project}.firebasestorage.app`,
);
console.log("get bucket", get.status, get.text.slice(0, 300));
