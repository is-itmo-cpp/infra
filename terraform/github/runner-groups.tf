locals {
  config  = yamldecode(file("${path.module}/../../infra.yaml"))
  secrets = yamldecode(file("${path.module}/../../secrets.yaml"))

  runners    = local.config.runners
  runner_vms = local.runners.vms
}

provider "github" {
  owner = local.runners.github_org
  token = local.secrets.runners.vars.github_token
}

resource "github_actions_runner_group" "runner" {
  for_each = local.runner_vms

  name                       = each.value.runner_group
  visibility                 = "all"
  allows_public_repositories = true
}
