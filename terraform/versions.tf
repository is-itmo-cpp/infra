terraform {
  required_version = ">= 1.6"

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.130"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.5"
    }
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.4"
    }
    github = {
      source  = "integrations/github"
      version = ">= 6.0"
    }
  }
}

provider "yandex" {}
