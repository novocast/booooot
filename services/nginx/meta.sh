#!/usr/bin/env bash
# services/nginx/meta.sh — nginx catalog metadata (task 006 draft; fleshed out in task 018).

catalog_nginx::register() {
  BOOT_CATALOG[nginx.name]="nginx"
  BOOT_CATALOG[nginx.label]="nginx"
  BOOT_CATALOG[nginx.description]="nginx web server with site/vhost scaffolding."
  BOOT_CATALOG[nginx.versions]="stable,mainline"
  BOOT_CATALOG[nginx.default_version]="stable"
  BOOT_CATALOG[nginx.targets]="direct,docker,vm"
  BOOT_CATALOG[nginx.configs]="vhost,server_name,http2"

  BOOT_CATALOG_CFG[nginx.vhost]="Scaffold a vhost|bool|on|"
  BOOT_CATALOG_CFG[nginx.server_name]="Server name|string|localhost|"
  BOOT_CATALOG_CFG[nginx.http2]="Enable HTTP/2|bool|on|"
}
