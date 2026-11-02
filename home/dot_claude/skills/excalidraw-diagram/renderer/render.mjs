#!/usr/bin/env node
import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, extname, join, resolve } from "node:path";
import { parseArgs } from "node:util";
import { fileURLToPath } from "node:url";
import { CONTENT_TYPES, ORIGIN, parseDiagram, resolveAsset } from "./lib.mjs";

const usage = "usage: render.mjs <file.excalidraw> [--output out.png] [--scale 2] [--width 1920] [--svg out.svg]";

function fail(message) {
  console.error(`render.mjs: ${message}`);
  process.exit(1);
}

const { values, positionals } = parseArgs({
  allowPositionals: true,
  options: {
    output: { type: "string", short: "o" },
    scale: { type: "string", short: "s", default: "2" },
    width: { type: "string", short: "w", default: "1920" },
    svg: { type: "string" },
  },
});
if (positionals.length !== 1) fail(usage);

const inputFile = resolve(positionals[0]);
const scale = Number(values.scale);
const maxWidth = Number(values.width);
if (!(scale > 0) || !(maxWidth > 0)) fail("--scale and --width must be positive numbers");
const outputFile = resolve(values.output ?? inputFile.replace(/\.excalidraw$/, "") + ".png");

if (!existsSync(inputFile)) fail(`input not found: ${inputFile}`);
let diagram;
try {
  diagram = parseDiagram(readFileSync(inputFile, "utf8"));
} catch (error) {
  fail(`${inputFile}: ${error.message}`);
}

const rendererDir = dirname(fileURLToPath(import.meta.url));
const assets = {
  pageFile: join(rendererDir, "page.html"),
  bundleFile: join(rendererDir, "dist/excalidraw.mjs"),
  fontsDir: join(rendererDir, "dist/fonts"),
};
if (!existsSync(assets.bundleFile)) {
  fail(`${assets.bundleFile} is missing: run "pnpm install --frozen-lockfile && node build.mjs" in ${rendererDir}`);
}

const { chromium } = await import("playwright-core");
let browser;
try {
  browser = await chromium.launch({ channel: "chrome", headless: true });
} catch (error) {
  fail(`could not launch Google Chrome (${error.message.split("\n")[0]}). Install Chrome and retry.`);
}

const blockedUrls = new Set();
let png;
let svg;
try {
  const page = await browser.newPage({
    viewport: { width: maxWidth, height: 1200 },
    deviceScaleFactor: scale,
  });
  await page.route("**/*", (route) => {
    const url = new URL(route.request().url());
    const file = url.origin === ORIGIN ? resolveAsset(url.pathname, assets) : null;
    if (!file || !existsSync(file)) {
      blockedUrls.add(url.href);
      return route.abort("blockedbyclient");
    }
    return route.fulfill({
      status: 200,
      contentType: CONTENT_TYPES[extname(file)],
      body: readFileSync(file),
    });
  });
  await page.goto(`${ORIGIN}/page.html`);
  await page.waitForFunction("window.__moduleReady === true", null, { timeout: 60000 });
  const result = await page.evaluate((data) => window.renderDiagram(data), diagram);
  if (!result.success) throw new Error(`Excalidraw could not render ${inputFile}: ${result.error}`);
  await page.waitForLoadState("networkidle");
  svg = await page.$eval("#root svg", (element) => element.outerHTML);
  png = await (await page.$("#root svg")).screenshot();
} catch (error) {
  await browser.close();
  fail(error.message);
}
await browser.close();

if (blockedUrls.size > 0) {
  fail(`blocked ${blockedUrls.size} outbound request(s), nothing written:\n${[...blockedUrls].join("\n")}`);
}

writeFileSync(outputFile, png);
if (values.svg) writeFileSync(resolve(values.svg), svg);
console.log(outputFile);
