# Environnement STAGING — même module, autre port. C'est tout.
include "root" {
  path = find_in_parent_folders("root.hcl")
}

inputs = {
  WP_PORT = 8082
}
