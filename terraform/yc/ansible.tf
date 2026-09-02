resource "local_file" "ansible_inventory" {
  filename             = "${path.module}/../../generated/ansible-inventory.yaml"
  directory_permission = "0755"
  file_permission      = "0644"

  content = yamlencode({
    runners = {
      vars = {
        ansible_user                 = local.runners.ssh.user
        ansible_ssh_private_key_file = local.runners.ssh.private_key_file
        runner_jobs                  = local.runners.jobs
        runner_image                 = local.runners.image
        runner_scale_set_name        = local.runners.scale_set_name
        github_config_url            = "https://github.com/${local.runners.github_org}"
      }
      hosts = {
        for name, vm in local.runner_vms : "vm-itmo-ci-${name}" => {
          ansible_host = yandex_compute_instance.runner[name].network_interface[0].nat_ip_address
          runner_group = vm.runner_group
          max_runners  = vm.max_runners
        }
      }
    }
  })
}
