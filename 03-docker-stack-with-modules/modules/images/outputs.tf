# image_id is what a container should reference (creates the implicit
# dependency "pull the image before starting the container").
output "image_ids" {
  description = "logical_key => image_id"
  value       = { for k, img in docker_image.this : k => img.image_id }
}

output "names" {
  description = "logical_key => image name"
  value       = { for k, img in docker_image.this : k => img.name }
}
