terraform {
  required_providers {
    dhi = {
      source = "registry.terraform.io/docker-hardened-images/dhi"
    }
  }
}

provider "dhi" {
  organization = "einhornhamster"
}

# --- Look up a single repository and its tag definitions ---

data "dhi_catalog_repository" "golang" {
  name = "golang"
}

output "golang_type" {
  value = data.dhi_catalog_repository.golang.type
}

# Full tag definitions list (id, display_name, fips_compliant, stig_certified, tag_names)
output "golang_tag_definitions" {
  value = data.dhi_catalog_repository.golang.tag_definitions
}

# Handy summary: map of tag definition ID → display_name (use the ID for dhi_customization.tag_definition_id)
output "golang_tag_definition_ids" {
  value = {
    for td in data.dhi_catalog_repository.golang.tag_definitions :
    td.id => td.display_name
  }
}

# Filter to only FIPS-compliant tag definitions
output "golang_fips_tag_definitions" {
  value = [
    for td in data.dhi_catalog_repository.golang.tag_definitions :
    td if td.fips_compliant
  ]
}

# --- List all image repositories ---

data "dhi_catalog_repositories" "images" {
  type_filter = ["IMAGE"]
}

output "image_count" {
  value = length(data.dhi_catalog_repositories.images.repositories)
}

# --- List all mirrors ---

data "dhi_mirrors" "all" {}

output "mirror_count" {
  value = data.dhi_mirrors.all.total_count
}
