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

# The Helm chart to customize, and its tag definitions
data "dhi_catalog_repository" "redis_chart" {
  name = "redis-chart"
}

# Set up the mirror of the chart first
resource "dhi_mirror" "redis_chart" {
  source_namespace   = "dhi"
  source_name        = "redis-chart"
  destination_name   = "dhi-redis-chart"
  create_destination = true
}

locals {
  redis_chart_tag = data.dhi_catalog_repository.redis_chart.tag_definitions[0]
}

# A Helm chart customization points each reference (variable) of the chart at one of:
#
#   1. dhi.io (free images): set only variable_name.
#   2. Another tag definition of a mirrored image: set repository and tag_definition_id.
#   3. A customization: set repository and customization_id.
#
# Every variable of the chart must be listed, once each, and variable_name must be the
# name the chart uses. Sub-charts can't point at a tag definition, only at a customization
# or dhi.io. The names of a chart's variables are in the dhi_customization state after
# `terraform import`, and in the error when one is missing.
resource "dhi_customization" "redis_chart" {
  name              = "Redis chart"
  source            = "dhi/redis-chart"
  destination       = dhi_mirror.redis_chart.destination_name
  tag_definition_id = local.redis_chart_tag.id

  # 1. Stays on dhi.io
  variable_mapping {
    variable_name = "BASH_REFERENCE"
  }

  # 2. Another tag definition of a mirrored image, here the "8-dev" variant of Redis.
  #    repository is namespace/name, or just name for a repository of your organization.
  variable_mapping {
    variable_name     = "REDIS_REFERENCE"
    repository        = "dhi-redis"
    tag_definition_id = "redis/debian-13/8-dev"
  }

  # 3. A customization of a mirrored image
  variable_mapping {
    variable_name    = "KUBECTL_REFERENCE"
    repository       = "dhi-kubectl"
    customization_id = "cz_10xsiwpln892u"
  }

  variable_mapping {
    variable_name = "REDIS_EXPORTER_REFERENCE"
  }
}
