output "ids" {
  description = "logical_key => volume id"
  value       = { for k, v in docker_volume.this : k => v.id }
}

output "names" {
  description = "logical_key => volume name"
  value       = { for k, v in docker_volume.this : k => v.name }
}
