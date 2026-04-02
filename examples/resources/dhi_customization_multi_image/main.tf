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

# ---------------------------------------------------------------------------
# Apply the same customization to golang, python and node.
# Per-image values (tag_pattern, entrypoint, cmd, environment) live in the
# map and are referenced via each.value.*; everything else is shared.
# ---------------------------------------------------------------------------

locals {
  images = {
    golang = {
      tag_pattern = "1-dev"
      entrypoint  = ["/usr/local/bin/go"]
      cmd         = ["version"]
      environment = {
        APP_ENV    = "production"
        LOG_LEVEL  = "info"
        GOMAXPROCS = "4"
      }
    }
    python = {
      tag_pattern = "3-dev"
      entrypoint  = ["/usr/local/bin/python3"]
      cmd         = ["--version"]
      environment = {
        APP_ENV   = "production"
        LOG_LEVEL = "info"
      }
    }
    node = {
      tag_pattern = "22-dev"
      entrypoint  = ["/usr/local/bin/node"]
      cmd         = ["--version"]
      environment = {
        APP_ENV   = "production"
        LOG_LEVEL = "info"
        NODE_ENV  = "production"
      }
    }
  }
}

data "dhi_catalog_repository" "this" {
  for_each = local.images
  name     = each.key
}

resource "dhi_mirror" "this" {
  for_each = local.images

  source_namespace   = "dhi"
  source_name        = each.key
  destination_name   = "dhi-${each.key}"
  create_destination = true
}

locals {
  tag_definitions = {
    for name, cfg in local.images : name => one([
      for td in data.dhi_catalog_repository.this[name].tag_definitions :
      td if contains(td.tag_names, cfg.tag_pattern)
    ])
  }
}

resource "dhi_customization" "this" {
  for_each = local.images

  name              = "custom"
  source            = "dhi/${each.key}"
  destination       = dhi_mirror.this[each.key].destination_name
  tag_definition_id = local.tag_definitions[each.key].id

  platforms = ["linux/amd64", "linux/arm64"]

  contents {
    packages = ["curl", "git", "jq", "wget"]
  }

  accounts {
    run_as           = "root"
    create_root_user = true
  }

  entrypoint  = each.value.entrypoint
  cmd         = each.value.cmd
  environment = each.value.environment

}

output "customization_ids" {
  value = { for name, c in dhi_customization.this : name => c.id }
}

output "tag_suffixes" {
  value = { for name, c in dhi_customization.this : name => c.tag_suffix }
}
