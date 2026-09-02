resource "yandex_iam_service_account" "vm_watch" {
  folder_id = data.yandex_resourcemanager_folder.default[local.home].id
  name      = "vm-watch"
}

resource "yandex_resourcemanager_folder_iam_member" "vm_watch_compute" {
  for_each = local.clouds

  folder_id = data.yandex_resourcemanager_folder.default[each.key].id
  role      = "compute.operator"
  member    = "serviceAccount:${yandex_iam_service_account.vm_watch.id}"
}

data "archive_file" "vm_watch" {
  type        = "zip"
  source_dir  = "${path.module}/../../functions/vm-watch"
  output_path = "${path.module}/../../generated/vm-watch.zip"
  excludes    = ["node_modules", "node_modules/**"]
}

resource "yandex_function" "vm_watch" {
  folder_id          = data.yandex_resourcemanager_folder.default[local.home].id
  name               = "vm-watch"
  runtime            = "nodejs22"
  entrypoint         = "index.handler"
  memory             = 128
  execution_timeout  = "60"
  service_account_id = yandex_iam_service_account.vm_watch.id

  user_hash = data.archive_file.vm_watch.output_sha256
  content {
    zip_filename = data.archive_file.vm_watch.output_path
  }
}

resource "yandex_function_iam_member" "vm_watch_invoker" {
  function_id = yandex_function.vm_watch.id
  role        = "functions.functionInvoker"
  member      = "serviceAccount:${yandex_iam_service_account.vm_watch.id}"
}

resource "yandex_function_trigger" "vm_watch_timer" {
  depends_on = [yandex_function_iam_member.vm_watch_invoker]

  folder_id = data.yandex_resourcemanager_folder.default[local.home].id
  name      = "vm-watch-timer"

  timer {
    cron_expression = "* * ? * * *"
    payload = jsonencode({
      vms = [
        for name, vm in local.runner_vms : {
          id            = yandex_compute_instance.runner[name].id
          mode          = vm.mode
          cronStart     = lookup(vm, "cron_start", null)
          durationHours = lookup(vm, "duration_hours", null)
          tz            = lookup(vm, "tz", null)
        }
      ]
    })
  }

  function {
    id                 = yandex_function.vm_watch.id
    service_account_id = yandex_iam_service_account.vm_watch.id
  }
}
