terraform {
  required_providers {
    dhi = {
      source = "docker-hardened-images/dhi"
    }
  }
}

provider "dhi" {
  organization = "my-org"
}

# Look up the source repository to get available tag definitions
data "dhi_catalog_repository" "golang" {
  name = "golang"
}

# Set up the mirror first — destination_namespace defaults to provider.organization
resource "dhi_mirror" "golang" {
  source_namespace   = "dhi"
  source_name        = "golang"
  destination_name   = "dhi-golang"
  create_destination = true
}

# Find the tag definition for the "1-dev" tag
locals {
  golang_dev_tag = one([
    for td in data.dhi_catalog_repository.golang.tag_definitions :
    td if contains(td.tag_names, "1-dev")
  ])
}

# Image customization using all available fields.
# destination without a "/" is automatically prefixed with provider.organization
resource "dhi_customization" "golang" {
  name              = "custom"
  source            = "dhi/golang"
  destination       = dhi_mirror.golang.destination_name
  tag_definition_id = local.golang_dev_tag.id

  platforms = ["linux/amd64", "linux/arm64"]

  contents {
    packages = ["curl", "git", "jq", "wget", "nodejs"]

    artifact {
      reference = "my-org/dhi-nginx:1.28-debian13-fips-dev"
      includes  = ["usr/bin"]
      excludes  = ["etc/ssl/certs/README"]
    }
  }

  accounts {
    run_as           = "appuser"
    create_root_user = false

    user {
      name = "appuser"
      uid  = 1001
      gid  = 1001
    }

    user {
      name = "nonroot"
      uid  = 65532
    }

    group {
      name    = "appgroup"
      gid     = 1001
      members = ["appuser"]
    }
  }

  environment = {
    APP_ENV    = "production"
    LOG_LEVEL  = "info"
    GOMAXPROCS = "4"
  }

  entrypoint = ["/usr/local/bin/go"]
  cmd        = ["version"]

  labels = {
    "com.example.managed-by"          = "terraform"
    "org.opencontainers.image.vendor" = "My Corp"
  }

  annotations = {
    "com.example.team" = "platform-engineering"
  }

  file {
    path    = "/etc/app/config.yaml"
    content = <<-EOT
      log_level: info
      port: 8080
    EOT
    mode    = "0644"
    uid     = 1001
    gid     = 1001
  }

  file {
    path    = "/etc/app/healthcheck.sh"
    content = <<-EOT
      #!/bin/sh
      curl -sf http://localhost:8080/health || exit 1
    EOT
    mode    = "0755"
  }
}

output "customization_id" {
  value = dhi_customization.golang.id
}

output "tag_suffix" {
  value = dhi_customization.golang.tag_suffix
}
