# 018 — Service: nginx

**Phase:** 3 — Services
**Status:** 📋 Not started
**Depends on:** 012–014

## Scope

- nginx from distro (or official repo) — version choice.
- Site/vhost scaffolding: create a site pointing at a docroot, PHP-FPM socket/port, upstreams; enable/disable sites.
- TLS: basic self-signed or let's-encrypt-ready structure (full certbot flow later).
- Config options: version, HTTP/HTTPS ports, server name, docroot, php integration on/off, worker settings.
- Common issues (doctor/024): "config test failed" (`nginx -t`), "port 80/443 in use", "permission denied on docroot".

## Acceptance criteria

- [ ] `nginx -t` always passes before any reload (never ship a broken config).
- [ ] Site scaffolding generates a valid vhost with sane defaults.
- [ ] Docker: official nginx image + mounted config/vhosts.

## Notes

- The "test before reload" rule is a non-negotiable safety invariant.
