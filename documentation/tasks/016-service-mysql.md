# 016 — Service: MySQL

**Phase:** 3 — Services
**Status:** 📋 Not started
**Depends on:** 012–014

## Scope

- MySQL server + client; version choice.
- Root password handling (secure default flow, storage in manifest/`~/.booooot`).
- Config options: root password, port, bind address, default charset/collation, buffer settings (small/medium/large presets).
- Common issues (doctor/024): "can't connect", "root auth via socket only", "port in use", "service not running".

## Acceptance criteria

- [ ] Direct: installs and secures; credentials surfaced once in a friendly way (and storable in manifest).
- [ ] Docker: official image, env-based credentials, persistent volume.
- [ ] Re-run safe — never wipes data, never resets an existing root password without asking.

## Notes

- Credential handling needs care: never echo passwords to logs; flag the security considerations in 023.
