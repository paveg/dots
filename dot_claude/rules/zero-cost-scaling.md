# Zero-Cost Scaling Pattern

When designing personal/indie web apps, especially those that may go viral:

## Client-Side Processing First

- Consider client-side AI processing (ONNX Runtime Web via WebAssembly/WebGPU) over server-side GPU
- Libraries like `@imgly/background-removal` enable browser-based neural network inference
- Initial model download (~40MB) is cached; subsequent uses are instant
- Add automatic fallback for constrained devices (e.g., 1024px → 768px → 512px)

## Don't Store User Data

- If processing can happen client-side, don't send data to a server
- No data storage = no privacy policy headaches, no security vulnerabilities, no storage costs
- Especially important for image uploads (EXIF GPS data, faces, upload vulnerabilities)

## Static Hosting with Unlimited Bandwidth

- Cloudflare Workers: unlimited bandwidth, free — ideal for viral traffic
  - Workers handles static assets, SSR, custom domains (Pages feature parity achieved)
  - Static asset requests are free and unlimited (don't count against 100K req/day Worker script limit)
  - 100K req/day limit applies only to dynamic Worker script execution
  - Pages is in maintenance mode (2025-04~); new projects should use Workers
- Compare: Vercel charges ~$360 for 1TB transfer; Cloudflare charges $0
- Vite + TypeScript for static builds; frameworks like React are optional

## Asset Optimization

- WebP with PNG fallback: WebP can be ~1.4% of PNG size
- At scale (500K users), this means 40GB vs 2.8TB for background images alone
- Impacts both hosting costs and user load times

## UI Simplicity as Feature

- Fewer options = consistent output format across all users
- Constraints breed creativity and community engagement (unified look in replies/quotes)
