import { resolve, sep } from "node:path";

export const ORIGIN = "http://excalidraw.local";

export const CONTENT_TYPES = {
  ".html": "text/html",
  ".mjs": "text/javascript",
  ".woff2": "font/woff2",
};

export function parseDiagram(text) {
  let data;
  try {
    data = JSON.parse(text);
  } catch (error) {
    throw new Error(`not valid JSON: ${error.message}`);
  }
  if (data?.type !== "excalidraw") {
    throw new Error('not an Excalidraw file: top-level "type" must be "excalidraw"');
  }
  if (!Array.isArray(data.elements) || data.elements.length === 0) {
    throw new Error('"elements" must be a non-empty array');
  }
  return data;
}

export function resolveAsset(urlPath, { pageFile, bundleFile, fontsDir }) {
  let path;
  try {
    path = decodeURIComponent(urlPath);
  } catch {
    return null;
  }
  if (path === "/page.html") return pageFile;
  if (path === "/excalidraw.mjs") return bundleFile;
  if (!path.startsWith("/fonts/")) return null;
  const root = resolve(fontsDir);
  const file = resolve(root, path.slice("/fonts/".length));
  return file.startsWith(root + sep) ? file : null;
}
