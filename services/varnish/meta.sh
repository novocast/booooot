#!/usr/bin/env bash
# services/varnish/meta.sh — Varnish catalog metadata (task 006 draft; fleshed out in task 021).

catalog_varnish::register() {
  BOOT_CATALOG[varnish.name]="varnish"
  BOOT_CATALOG[varnish.label]="Varnish"
  BOOT_CATALOG[varnish.description]="Varnish cache with basic cache configuration."
  BOOT_CATALOG[varnish.versions]="7.4,7.5,7.6"
  BOOT_CATALOG[varnish.default_version]="7.5"
  BOOT_CATALOG[varnish.targets]="direct,docker,vm"
  BOOT_CATALOG[varnish.configs]="cache_size,backend_port,admin_port"

  BOOT_CATALOG_CFG[varnish.cache_size]="Cache size (e.g. 256m)|string|256m|"
  BOOT_CATALOG_CFG[varnish.backend_port]="Backend port|int|8080|"
  BOOT_CATALOG_CFG[varnish.admin_port]="Admin port|int|6082|"
}
