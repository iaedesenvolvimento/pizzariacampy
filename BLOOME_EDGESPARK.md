# Bloome EdgeSpark Binding: pizzaria-campy

Project ID: e538dac4-63f8-443f-968e-c4a384e52a29
Base URL: https://master-opossum-2815.youware.pro
Environment: production

Before writing EdgeSpark code:

1. Read `../../skills/bloome/references/edgespark.md`.
2. If official EdgeSpark skills were just installed, read:
   - `../../skills/building-edgespark-apps/SKILL.md`
   - `../../skills/edgespark-frontend-design/SKILL.md`
3. Write backend routes in `server/src/index.ts`.
4. Use `server/src/bloome-bridge.ts`; do not rewrite silent sign-in from scratch.
5. Keep `server/src/defs/runtime.ts`; the bridge reads Bloome config from EdgeSpark secrets.
6. In `server/src/index.ts`, call `installBloomeBridge(app)` before business routes.
7. Use `ResonWidget.edgespark.fetch("/api/public/...")` in widget frontend code.
8. Do not mirror verified EdgeSpark data into `ResonWidget.state`.
9. Do not hand-create a different `src/` or move files out of `server/`.

Deploy with the `nextSteps` returned by `edgespark project create/info/verify`.
