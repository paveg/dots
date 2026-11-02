import { build } from "esbuild";
import { cpSync, mkdirSync, renameSync, rmSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const rendererDir = dirname(fileURLToPath(import.meta.url));
const distDir = join(rendererDir, "dist");
const stagingDir = join(rendererDir, "dist.tmp");

rmSync(stagingDir, { recursive: true, force: true });
mkdirSync(stagingDir);

try {
  await build({
    stdin: {
      contents: 'export { exportToSvg } from "@excalidraw/excalidraw";',
      resolveDir: rendererDir,
    },
    outfile: join(stagingDir, "excalidraw.mjs"),
    bundle: true,
    format: "esm",
    platform: "browser",
    target: "es2022",
    conditions: ["production"],
    define: { "process.env.NODE_ENV": '"production"' },
    loader: { ".css": "empty", ".woff2": "empty" },
    minify: true,
    logLevel: "warning",
  });

  cpSync(join(rendererDir, "node_modules/@excalidraw/excalidraw/dist/prod/fonts"), join(stagingDir, "fonts"), {
    recursive: true,
  });

  rmSync(distDir, { recursive: true, force: true });
  renameSync(stagingDir, distDir);
} finally {
  rmSync(stagingDir, { recursive: true, force: true });
}
console.log(`built ${distDir}`);
