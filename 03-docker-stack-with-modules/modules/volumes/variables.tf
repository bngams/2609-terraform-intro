variable "volumes" {
  description = "Volumes to create: { logical_key = \"docker_volume_name\" }"
  type        = map(string)
  # example:
  # { wp = "wordpress_data_tf2609", db = "db_data_tf2609" }
}
