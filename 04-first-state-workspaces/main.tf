# Une SEULE config, plusieurs states grâce aux WORKSPACES.
# `terraform.workspace` vaut "default", puis "dev" / "test" une fois créés.
resource "local_file" "greeting" {
  content  = "Hello from workspace ${terraform.workspace} !\n"
  filename = "${path.module}/output/greeting_${terraform.workspace}.txt"
}

output "current_workspace" {
  value = terraform.workspace
}

output "file_path" {
  value = local_file.greeting.filename
}
