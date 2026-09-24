terraform {
  required_providers {
    local = {
      source = "hashicorp/local"
      version = "2.9.1"
    }
    # Add other required providers here if needed
    # ...
  }
}

provider "local" {
  # Configuration options
}