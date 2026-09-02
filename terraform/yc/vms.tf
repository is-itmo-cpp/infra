locals {
  config = yamldecode(file("${path.module}/../../infra.yaml"))

  home       = local.config.home
  clouds     = local.config.clouds
  runners    = local.config.runners
  runner_vms = local.runners.vms

  # https://yandex.cloud/en/docs/troubleshooting/compute/known-issues/permission-denied-error-when-connected-as-user-created-from-terraform-manifest
  cloud_init = "#cloud-config\n${yamlencode({
    users = [{
      name                = local.runners.ssh.user
      groups              = ["sudo"]
      shell               = "/bin/bash"
      sudo                = "ALL=(ALL) NOPASSWD:ALL"
      ssh_authorized_keys = [trimspace(file(pathexpand(local.runners.ssh.public_key_file)))]
    }]
  })}"
}

data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2404-lts"
}

data "yandex_resourcemanager_folder" "default" {
  for_each = local.clouds

  cloud_id = each.value.cloud_id
  name     = "default"
}

data "yandex_vpc_subnet" "default" {
  for_each = local.runner_vms

  folder_id = data.yandex_resourcemanager_folder.default[each.value.cloud].id
  name      = "default-${each.value.zone}"
}

resource "terraform_data" "cloud_init" {
  triggers_replace = local.cloud_init
}

resource "yandex_compute_instance" "runner" {
  for_each = local.runner_vms

  folder_id   = data.yandex_resourcemanager_folder.default[each.value.cloud].id
  name        = "vm-itmo-ci-${each.key}"
  zone        = each.value.zone
  platform_id = "standard-v3"

  resources {
    cores  = each.value.cores
    memory = each.value.memory
  }

  scheduling_policy {
    preemptible = true
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      type     = each.value.disk_type
      size     = each.value.disk_size
    }
  }

  network_interface {
    subnet_id = data.yandex_vpc_subnet.default[each.key].id
    nat       = true
  }

  metadata = {
    user-data = local.cloud_init
  }

  lifecycle {
    replace_triggered_by = [terraform_data.cloud_init]
  }

  allow_stopping_for_update = true
}
