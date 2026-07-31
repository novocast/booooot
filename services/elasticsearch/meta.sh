#!/usr/bin/env bash
# services/elasticsearch/meta.sh — Elasticsearch catalog metadata (task 006 draft; fleshed out in task 020).

catalog_elasticsearch::register() {
  BOOT_CATALOG[elasticsearch.name]="elasticsearch"
  BOOT_CATALOG[elasticsearch.label]="Elasticsearch"
  BOOT_CATALOG[elasticsearch.description]="Elasticsearch with JVM memory settings."
  BOOT_CATALOG[elasticsearch.versions]="7.17,8.15,8.16"
  BOOT_CATALOG[elasticsearch.default_version]="8.15"
  BOOT_CATALOG[elasticsearch.targets]="direct,docker,vm"
  BOOT_CATALOG[elasticsearch.configs]="heap_size,cluster_name,data_dir"

  BOOT_CATALOG_CFG[elasticsearch.heap_size]="JVM heap size (e.g. 512m)|string|512m|"
  BOOT_CATALOG_CFG[elasticsearch.cluster_name]="Cluster name|string|booooot|"
  BOOT_CATALOG_CFG[elasticsearch.data_dir]="Data directory|string|/var/lib/elasticsearch|"
}
