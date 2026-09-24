# Maps keyed by the SAME logical key given in input, so consumers can wire by name.
output "ids" {
  description = "logical_key => network id"
  value       = { for k, n in docker_network.this : k => n.id }
}

output "names" {
  description = "logical_key => network name"
  value       = { for k, n in docker_network.this : k => n.name }
}
