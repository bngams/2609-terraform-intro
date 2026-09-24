variable "networks" {
  description = "Networks to create: { logical_key = \"docker_network_name\" }"
  type        = map(string)
  # example:
  # { wp = "wp_net_tf2609" }
}
