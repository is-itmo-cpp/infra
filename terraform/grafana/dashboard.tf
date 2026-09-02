locals {
  secrets = yamldecode(file("${path.module}/../../secrets.yaml"))
}

provider "grafana" {
  url  = local.secrets.runners.vars.grafana.url
  auth = local.secrets.runners.vars.grafana.service_account_token
}

resource "grafana_dashboard" "runners" {
  config_json = file("${path.module}/../../grafana/runners.json")
  overwrite   = true
}
