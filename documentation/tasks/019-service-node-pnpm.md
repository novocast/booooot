# 019 — Service: Node.js + pnpm

**Phase:** 3 — Services
**Status:** 📋 Not started
**Depends on:** 012–014

## Scope

- Node.js LTS/current via `nodesource` (direct) or official image (docker); **pnpm** installed via corepack or standalone.
- Config options: release line (LTS/current), exact version, pnpm via corepack yes/no, global tools list (e.g. typescript, pm2).
- Common issues (doctor/024): "node not on PATH after install", "pnpm missing", "nvm conflict", "corepack disabled".

## Acceptance criteria

- [ ] `node -v` / `pnpm -v` correct after direct install; no nvm conflicts detected.
- [ ] Docker: node image + corepack-enabled pnpm; compose integration.
- [ ] Global tool installs are opt-in and recorded in the manifest.

## Notes

- Watch PATH/`update-alternatives` handling — a frequent real-world footgun.
