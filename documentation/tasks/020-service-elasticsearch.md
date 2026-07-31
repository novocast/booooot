# 020 — Service: Elasticsearch

**Phase:** 3 — Services
**Status:** 📋 Not started
**Depends on:** 012–014

## Scope

- Elasticsearch from the official repo; version choice (be mindful of the licensing/version landscape).
- JVM/memory handling: heap settings, `bootstrap.memory_lock`, vm.max_map_count check (a classic install blocker).
- Config options: version, heap size, cluster/node name, port, security on/off.
- Common issues (doctor/024): "vm.max_map_count too low", "max file descriptors", "heap too large for box", "service won't start".

## Acceptance criteria

- [ ] Direct: repo install + systemd unit working; memory settings sized sanely for the box.
- [ ] Docker: official image with env-based JVM/memory config; compose integration.
- [ ] Pre-flight check reports the known blockers (mmap, ulimits) with the fix command.

## Notes

- Elasticsearch is the "fiddly one" — it earns its own common-issues list.
