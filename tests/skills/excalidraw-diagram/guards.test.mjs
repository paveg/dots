import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { after, describe, test } from "node:test";
import { fileURLToPath } from "node:url";

const rendererDir = resolve(fileURLToPath(import.meta.url), "../../../../home/dot_claude/skills/excalidraw-diagram/renderer");
const { parseDiagram, resolveAsset } = await import(join(rendererDir, "lib.mjs"));

const workdir = mkdtempSync(join(tmpdir(), "excalidraw-guards-"));
after(() => rmSync(workdir, { recursive: true, force: true }));

describe("parseDiagram", () => {
  const element = { id: "a", type: "rectangle", x: 0, y: 0 };

  test("accepts a minimal diagram", () => {
    const data = parseDiagram(JSON.stringify({ type: "excalidraw", elements: [element] }));
    assert.equal(data.elements.length, 1);
  });

  test("rejects text that is not JSON", () => {
    assert.throws(() => parseDiagram("{not json"), /not valid JSON/);
  });

  test("rejects JSON without type excalidraw", () => {
    assert.throws(() => parseDiagram(JSON.stringify({ type: "other", elements: [element] })), /not an Excalidraw file/);
    assert.throws(() => parseDiagram("null"), /not an Excalidraw file/);
  });

  test("rejects missing or empty elements", () => {
    assert.throws(() => parseDiagram(JSON.stringify({ type: "excalidraw" })), /non-empty array/);
    assert.throws(() => parseDiagram(JSON.stringify({ type: "excalidraw", elements: [] })), /non-empty array/);
  });
});

describe("resolveAsset", () => {
  const assets = { pageFile: "/r/page.html", bundleFile: "/r/dist/excalidraw.mjs", fontsDir: "/r/dist/fonts" };

  test("serves the page, the bundle and files under fonts", () => {
    assert.equal(resolveAsset("/page.html", assets), "/r/page.html");
    assert.equal(resolveAsset("/excalidraw.mjs", assets), "/r/dist/excalidraw.mjs");
    assert.equal(resolveAsset("/fonts/Excalifont/a.woff2", assets), "/r/dist/fonts/Excalifont/a.woff2");
  });

  test("refuses anything else", () => {
    assert.equal(resolveAsset("/", assets), null);
    assert.equal(resolveAsset("/favicon.ico", assets), null);
    assert.equal(resolveAsset("/fonts", assets), null);
    assert.equal(resolveAsset("/fonts/", assets), null);
  });

  test("refuses path traversal out of fonts", () => {
    assert.equal(resolveAsset("/fonts/../../etc/passwd", assets), null);
    assert.equal(resolveAsset("/fonts/%2e%2e/%2e%2e/etc/passwd", assets), null);
    assert.equal(resolveAsset("/fonts/../fonts-evil/a.woff2", assets), null);
    assert.equal(resolveAsset("/fonts/%zz", assets), null);
  });
});

describe("render.mjs input validation", () => {
  const run = (...args) => spawnSync("node", [join(rendererDir, "render.mjs"), ...args], { encoding: "utf8" });
  const write = (name, content) => {
    const file = join(workdir, name);
    writeFileSync(file, content);
    return file;
  };

  test("fails on a missing input file before touching a browser", () => {
    const result = run(join(workdir, "missing.excalidraw"));
    assert.equal(result.status, 1);
    assert.match(result.stderr, /input not found/);
  });

  test("fails on invalid JSON", () => {
    const result = run(write("bad.excalidraw", "{nope"));
    assert.equal(result.status, 1);
    assert.match(result.stderr, /not valid JSON/);
  });

  test("fails on a non-Excalidraw document", () => {
    const result = run(write("other.excalidraw", '{"type":"other","elements":[{}]}'));
    assert.equal(result.status, 1);
    assert.match(result.stderr, /not an Excalidraw file/);
  });

  test("fails on empty elements", () => {
    const result = run(write("empty.excalidraw", '{"type":"excalidraw","elements":[]}'));
    assert.equal(result.status, 1);
    assert.match(result.stderr, /non-empty array/);
  });

  test("fails without an input argument", () => {
    const result = run();
    assert.equal(result.status, 1);
    assert.match(result.stderr, /usage/);
  });
});
