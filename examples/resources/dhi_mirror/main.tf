terraform {
  required_providers {
    dhi = {
      source = "registry.terraform.io/docker-hardened-images/dhi"
    }
  }
}

provider "dhi" {
  organization = "acme-org"
}

# destination_namespace defaults to the provider's organization ("acme-org")
resource "dhi_mirror" "golang" {
  source_namespace   = "dhi"
  source_name        = "golang"
  destination_name   = "dhi-golang"
  create_destination = true
}

resource "dhi_mirror" "python" {
  source_namespace   = "dhi"
  source_name        = "python"
  destination_name   = "dhi-python"
  create_destination = true
}

output "golang_mirror_id" {
  value = dhi_mirror.golang.id
}

output "python_mirror_id" {
  value = dhi_mirror.python.id
}
