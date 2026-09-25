# Environnement DEV — n'hérite que de la config globale + ce qui lui est propre.
include "root" {
  path = find_in_parent_folders("root.hcl")
}

# Seule variable réellement spécifique à cet environnement : le port.
# (SERVER_NAME = "dev" est déduit automatiquement du nom du dossier.)
inputs = {
  WP_PORT = 8081
}
