#!/usr/bin/env bash
# services/node/meta.sh — Node.js + pnpm catalog metadata (task 006 draft; fleshed out in task 019).

catalog_node::register() {
  BOOT_CATALOG[node.name]="node"
  BOOT_CATALOG[node.label]="Node.js + pnpm"
  BOOT_CATALOG[node.description]="Node.js (LTS or current) with pnpm via corepack or standalone."
  BOOT_CATALOG[node.versions]="20,22,current"
  BOOT_CATALOG[node.default_version]="22"
  BOOT_CATALOG[node.targets]="direct,docker,vm"
  BOOT_CATALOG[node.configs]="pnpm_method,global_installs"

  BOOT_CATALOG_CFG[node.pnpm_method]="pnpm install method|select|corepack|corepack,standalone"
  BOOT_CATALOG_CFG[node.global_installs]="Allow global installs|bool|on|"
}
