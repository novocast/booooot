#!/usr/bin/env bash
# services/postgresql/meta.sh — PostgreSQL catalog metadata (task 006 draft; fleshed out in task 017).

catalog_postgresql::register() {
  BOOT_CATALOG[postgresql.name]="postgresql"
  BOOT_CATALOG[postgresql.label]="PostgreSQL"
  BOOT_CATALOG[postgresql.description]="PostgreSQL server + client with version choices."
  BOOT_CATALOG[postgresql.versions]="15,16,17"
  BOOT_CATALOG[postgresql.default_version]="16"
  BOOT_CATALOG[postgresql.targets]="direct,docker,vm"
  BOOT_CATALOG[postgresql.configs]="postgres_password,port,data_dir,remote_access"

  BOOT_CATALOG_CFG[postgresql.postgres_password]="postgres superuser password|string||"
  BOOT_CATALOG_CFG[postgresql.port]="Port|int|5432|"
  BOOT_CATALOG_CFG[postgresql.data_dir]="Data directory|string|/var/lib/postgresql|"
  BOOT_CATALOG_CFG[postgresql.remote_access]="Allow remote connections|bool|off|"
}
