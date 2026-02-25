{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Monitoring and observability
    grafana-loki
    promql-cli
    atac
    termshark

    # Database and messaging tools
    postgresql
    postgresql_jdbc
    pghero
    go-migrate
    clickhouse-cli
    kcat
    kafkactl
  ];
}
