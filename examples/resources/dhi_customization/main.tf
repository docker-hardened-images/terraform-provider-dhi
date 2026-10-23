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
# Every field except name, source, destination, tag_definition_id and platforms is optional.
# A field you leave out is inherited from the tag definition; a field you set overrides
# the inherited value. Keep only the fields you want to override.
# destination without a "/" is automatically prefixed with provider.organization
resource "dhi_customization" "golang" {
  name              = "custom"
  source            = "dhi/golang"
  destination       = dhi_mirror.golang.destination_name
  tag_definition_id = local.golang_dev_tag.id

  # Required. Use platforms the tag definition supports, for example "linux/amd64" and
  # "linux/arm64". data.dhi_catalog_repository.golang.platforms lists the supported ones.
  platforms = ["linux/amd64", "linux/arm64"]

  # Layer compression: GZIP or ZSTD. Leave it out to keep the default; setting it
  # overrides the default.
  compression = "ZSTD"

  contents {
    packages = ["curl", "git", "jq", "wget", "nodejs"]

    artifact {
      reference = "my-org/dhi-nginx:1.28-debian13-fips-dev"
      includes  = ["usr/bin"] # optional
      excludes  = ["etc/ssl/certs/README"] # optional
    }
  }

  # Symlinks to create in the image. uid/gid are optional and are omitted
  # when not set.
  symlink {
    path   = "/usr/local/foo"
    source = "/usr/local/bar"
    uid    = 1000
    gid    = 1000
  }

  symlink {
    path   = "/usr/local/bin/foo"
    source = "/usr/local/bin/bar"
  }

  # Each field you set overrides the inherited one. Setting user or group replaces the
  # inherited list instead of adding to it.
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

  # Environment variables, labels and annotations are merged by key with the inherited
  # ones: a key you set overrides the inherited key with the same name.
  environment = {
    APP_ENV    = "production"
    LOG_LEVEL  = "info"
    GOMAXPROCS = "4"
  }

  entrypoint = ["/usr/local/bin/go"]
  cmd        = ["version"]

  # Working directory of the image. Leave it out to inherit the tag definition's
  # working directory; setting it overrides the inherited value.
  working_directory = "/app"

  labels = {
    "com.example.managed-by"          = "terraform"
    "org.opencontainers.image.vendor" = "My Corp"
  }

  annotations = {
    "com.example.team" = "platform-engineering"
  }

  # Every field of a file is required.
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
    uid     = 1001
    gid     = 1001
  }
}

output "customization_id" {
  value = dhi_customization.golang.id
}

output "tag_suffix" {
  value = dhi_customization.golang.tag_suffix
}
