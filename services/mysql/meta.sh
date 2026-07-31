#!/usr/bin/env bash
# services/mysql/meta.sh — MySQL catalog metadata (task 006 draft; fleshed out in task 016).

catalog_mysql::register() {
  BOOT_CATALOG[mysql.name]="mysql"
  BOOT_CATALOG[mysql.label]="MySQL"
  BOOT_CATALOG[mysql.description]="MySQL server + client with version choices and root password handling."
  BOOT_CATALOG[mysql.versions]="8.0,8.4"
  BOOT_CATALOG[mysql.default_version]="8.0"
  BOOT_CATALOG[mysql.targets]="direct,docker,vm"
  BOOT_CATALOG[mysql.configs]="root_password,port,data_dir,remote_access"

  BOOT_CATALOG_CFG[mysql.root_password]="Root password|string||"
  BOOT_CATALOG_CFG[mysql.port]="Port|int|3306|"
  BOOT_CATALOG_CFG[mysql.data_dir]="Data directory|string|/var/lib/mysql|"
  BOOT_CATALOG_CFG[mysql.remote_access]="Allow remote connections|bool|off|"
}
