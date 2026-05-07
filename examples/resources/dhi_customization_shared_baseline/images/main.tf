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
# Apply the same baseline (defined in the ../baseline child module) to two
# different images: golang and node. Per-image values live in the map
# below; everything else comes from module.baseline.*.
#
# This is the root module — run terraform from this directory:
#   cd images/
#   terraform init
#   terraform apply
# ---------------------------------------------------------------------------

module "baseline" {
  source = "../baseline"
}

locals {
  images = {
    golang = {
      tag_pattern = "1-dev"
      entrypoint  = ["/usr/local/bin/go"]
      cmd         = ["version"]
    }
    node = {
      tag_pattern = "22-dev"
      entrypoint  = ["/usr/local/bin/node"]
      cmd         = ["--version"]
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

  # Shared baseline values
  platforms   = module.baseline.platforms
  environment = module.baseline.environment
  labels      = module.baseline.labels
  annotations = module.baseline.annotations

  contents {
    packages = module.baseline.packages
  }

  accounts {
    run_as           = module.baseline.accounts.run_as
    create_root_user = module.baseline.accounts.create_root_user

    dynamic "user" {
      for_each = module.baseline.accounts.users
      content {
        name = user.value.name
        uid  = user.value.uid
        gid  = try(user.value.gid, null)
      }
    }

    dynamic "group" {
      for_each = module.baseline.accounts.groups
      content {
        name    = group.value.name
        gid     = group.value.gid
        members = try(group.value.members, null)
      }
    }
  }

  dynamic "file" {
    for_each = module.baseline.files
    content {
      path    = file.value.path
      content = file.value.content
      mode    = try(file.value.mode, null)
      uid     = try(file.value.uid, null)
      gid     = try(file.value.gid, null)
    }
  }

  # Per-image overrides
  entrypoint = each.value.entrypoint
  cmd        = each.value.cmd
}

output "customization_ids" {
  value = { for name, c in dhi_customization.this : name => c.id }
}

output "tag_suffixes" {
  value = { for name, c in dhi_customization.this : name => c.tag_suffix }
}
