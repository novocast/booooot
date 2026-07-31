# 021 — Service: Varnish

**Phase:** 3 — Services
**Status:** 📋 Not started
**Depends on:** 012–014

## Scope

- Varnish from distro/official repo; version choice.
- VCL scaffolding: a default VCL with sane cache rules, backend pointing at nginx/app (port config), purge helpers.
- Config options: version, listen port, backend host/port, memory (malloc) size, default TTL.
- Common issues (doctor/024): "backend unhealthy", "varnishlog/varnishadm missing", "port conflict", "VCL compile failed".

## Acceptance criteria

- [ ] `varnishd -C` (VCL compile check) passes before apply, mirroring nginx's `-t` rule.
- [ ] Direct: systemd unit running with configured memory/backend.
- [ ] Docker: official image + mounted VCL + admin port.

## Notes

- Varnish pairs naturally with nginx/app backends — the wizard should offer backend pick-from-installed.
