#!/usr/bin/env bash
# services/php/meta.sh — PHP catalog metadata (task 006 draft; fleshed out in task 015).

catalog_php::register() {
  BOOT_CATALOG[php.name]="php"
  BOOT_CATALOG[php.label]="PHP"
  BOOT_CATALOG[php.description]="Multiple PHP versions (8.1–8.4) with per-version package sets and extensions."
  BOOT_CATALOG[php.versions]="8.1,8.2,8.3,8.4"
  BOOT_CATALOG[php.default_version]="8.3"
  BOOT_CATALOG[php.targets]="direct,docker,vm"
  BOOT_CATALOG[php.configs]="extensions,opcache,memory_limit,timezone"

  BOOT_CATALOG_CFG[php.extensions]="PHP extensions|checklist|curl,mbstring,xml,zip|curl,gd,intl,mbstring,mysql,opcache,redis,soap,xml,zip"
  BOOT_CATALOG_CFG[php.opcache]="Enable OPcache|bool|on|"
  BOOT_CATALOG_CFG[php.memory_limit]="Memory limit (e.g. 256M)|string|256M|"
  BOOT_CATALOG_CFG[php.timezone]="Default timezone|select|UTC|UTC,Europe/London,Europe/Berlin,Europe/Paris,America/New_York,Asia/Tokyo"
}
