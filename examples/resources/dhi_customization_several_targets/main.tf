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

# Set up the mirror first
resource "dhi_mirror" "golang" {
  source_namespace   = "dhi"
  source_name        = "golang"
  destination_name   = "dhi-golang"
  create_destination = true
}

# One image customization applied to several tag definitions at once.
# With several targets, the targets must:
#   - be image repositories (a Helm chart customization has exactly one target, see the
#     dhi_customization_helm_chart example, and can't be mixed with images),
#   - be in the same destination namespace (source and destination are always namespace/name),
#   - share a distribution, for example all alpine-3.23.
# accounts, entrypoint, cmd and working_directory can only be set with one target.
# Every field except name, platforms and target is optional. A field you leave out is
# inherited from the tag definition of each target; a field you set overrides it.
# A single target block works the same as source, destination and tag_definition_id.
resource "dhi_customization" "golang" {
  name = "golang"

  # Required. Use platforms every target's tag definition supports.
  platforms = ["linux/amd64", "linux/arm64"]

  # data.dhi_catalog_repository.<name>.tag_definitions lists the tag definition ids.
  # The targets can also use different destination repositories.
  target {
    source            = "dhi/golang"
    destination       = "${dhi_mirror.golang.destination_namespace}/${dhi_mirror.golang.destination_name}"
    tag_definition_id = "golang/alpine-3.23/1.26"
  }

  target {
    source            = "dhi/golang"
    destination       = "${dhi_mirror.golang.destination_namespace}/${dhi_mirror.golang.destination_name}"
    tag_definition_id = "golang/alpine-3.23/1.26-dev"
  }

  compression = "ZSTD"

  contents {
    packages = ["curl", "git"]
  }

  environment = {
    APP_ENV = "production"
  }

  labels = {
    "com.something.managed-by" = "terraform"
  }

  #annotations = {
  #  "com.something.team" = "platform-engineering"
  #}
}

output "customization_id" {
  value = dhi_customization.golang.id
}
