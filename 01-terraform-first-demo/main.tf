variable "file_content" {
  description = "The content to write to the file"
  type        = string
  default     = "Hello world!!!!!????"
}

variable "file_name" {
  description = "The name of the file to write to"
  type        = string
  default     = "my_first_tf_file.txt"
}

# variable locale (internal logic only, not meant to be modified by users)
locals {
  output_dir = "${path.module}/output"
}

resource "local_file" "my_first_tf_file" {
  content  = var.file_content
  filename = "${local.output_dir}/${var.file_name}"
}


# output example
output "my_first_tf_file_path" {
  value       = local_file.my_first_tf_file.filename
  description = "The path to the generated file"
  sensitive   = false
}

output "my_first_tf_file_checksum" {
  value = local_file.my_first_tf_file.content_md5
  description = "The MD5 checksum of the generated file"
  sensitive = false
}