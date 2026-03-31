terraform {
  required_providers {
    dhi = {
      source = "registry.terraform.io/docker-hardened-images/dhi"
    }
  }
}

# Configure the DHI provider.
# Credentials can also be set via environment variables:
#   DHI_ORG, DOCKER_USERNAME, DOCKER_PASSWORD
provider "dhi" {
  organization = "my-org"
}
