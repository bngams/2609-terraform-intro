resource "local_file" "my_first_tf_file" {
  content  = "Hello world!!!"
  filename = "${path.module}/output/my_first_tf_file.txt"
}
