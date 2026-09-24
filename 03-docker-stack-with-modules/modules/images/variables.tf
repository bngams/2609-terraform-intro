variable "images" {
  description = "Images to pull: { logical_key = \"image:tag\" }"
  type        = map(string)
  # example:
  # { wordpress = "wordpress:latest", mariadb = "mariadb:10.6.4-focal" }
}
