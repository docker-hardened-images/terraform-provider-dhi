<img alt="dhi-banner" src="https://github.com/user-attachments/assets/fc0ca203-3f25-4ae5-aa8e-e3918bbcc31f" />

# Docker Hardened Images - Terraform Provider

The official Terraform provider for [Docker Hardened Images (DHI)](https://www.docker.com/products/hardened-images/) — manage mirrors, customizations, and catalog lookups using infrastructure as code.

## 🚀 Quick Start

```hcl
terraform {
  required_providers {
    dhi = {
      source  = "docker-hardened-images/dhi"
      version = "~> 0.1"
    }
  }
}

provider "dhi" {
  organization = "my-org"
}
```

### Authentication

The provider authenticates via Docker Hub credentials, which are exchanged for a bearer token.

| Setting | Provider Attribute | Environment Variable |
|---------|-------------------|---------------------|
| Docker Hub Username | `docker_hub_username` | `DOCKER_USERNAME` |
| Docker Hub Password/PAT | `docker_hub_password` | `DOCKER_PASSWORD` |
| Organization | `organization` | `DHI_ORG` |

```bash
export DOCKER_USERNAME="your-username"
export DOCKER_PASSWORD="your-pat"
export DHI_ORG="your-org"
```

## 📁 Resources & Data Sources

### Resources

| Resource | Description |
|----------|-------------|
| `dhi_customization` | Manage image and Helm chart customizations (full CRUD + import) |
| `dhi_mirror` | Manage mirrored repository configurations |

### Data Sources

| Data Source | Description |
|-------------|-------------|
| `dhi_catalog_repository` | Look up a single DHI catalog repository by name |
| `dhi_catalog_repositories` | List all DHI catalog repositories with optional type filter |
| `dhi_mirrors` | List all mirrored repositories for the organization |

## 📖 Usage Examples

### Mirror a Repository

```hcl
resource "dhi_mirror" "golang" {
  source_namespace   = "dhi"
  source_name        = "golang"
  destination_name   = "dhi-golang"
  create_destination = true
}
```

`destination_namespace` defaults to the provider's `organization` if omitted.

### Discover Tag Definitions

```hcl
data "dhi_catalog_repository" "golang" {
  name = "golang"
}

output "tag_definitions" {
  value = {
    for td in data.dhi_catalog_repository.golang.tag_definitions :
    td.id => td.display_name
  }
}
```

### Create an Image Customization

A customization is built on a tag definition and inherits its settings. Leave a field out to inherit the tag definition's value. Set a field to override it. Nothing is filled in for you, so what you write is what is stored, and later changes to the tag definition reach the fields you left out.

Only set a field when you want to override it. The example below sets every field that can be set. In your own configuration, keep only the ones you want to override.

```hcl
locals {
  dev_tag = one([
    for td in data.dhi_catalog_repository.golang.tag_definitions :
    td if contains(td.tag_names, "1-dev")
  ])
}

resource "dhi_customization" "golang" {
  # ---- Required. Not inherited. ----
  name              = "custom"
  source            = "dhi/golang"
  destination       = dhi_mirror.golang.destination_name # an existing repository
  tag_definition_id = local.dev_tag.id

  # Required for image customizations. Use platforms the tag definition supports,
  # for example "linux/amd64" and "linux/arm64".
  platforms = ["linux/amd64", "linux/arm64"]

  # ---- Optional. Leave out what you do not want to override. ----

  # Inherited if left out. Setting it overrides the default compression: "GZIP" or "ZSTD".
  compression = "ZSTD"

  # Inherited if left out. Setting a key overrides the inherited key with the same name;
  # the other inherited keys are kept.
  environment = {
    APP_ENV = "production"
  }
  labels = {
    "org.opencontainers.image.vendor" = "Acme Corp"
  }
  annotations = {
    "com.example.team" = "platform-engineering"
  }

  # Inherited if left out. Setting it replaces the inherited value.
  entrypoint = ["/usr/local/bin/go"]
  cmd        = ["version"]

  # Inherited if left out. Setting it overrides the inherited working directory.
  working_directory = "/app"

  # Inherited if left out. Each field you set overrides the inherited one. Setting user or
  # group replaces the inherited list instead of adding to it.
  accounts {
    run_as           = "nonroot"
    create_root_user = false

    user {
      name = "nonroot"
      uid  = 65532
      gid  = 65532 # optional
    }

    group {
      name    = "nonroot"
      gid     = 65532
      members = ["nonroot"] # optional
    }
  }

  # Additional packages and artifacts. Inherited if left out.
  contents {
    packages = ["curl", "git", "jq"]

    artifact {
      reference = "docker.io/acme/tools:1.0"
      includes  = ["usr/bin"] # optional
      excludes  = ["etc/ssl"] # optional
    }
  }

  # Optional files to add to the image.
  # Every field of a file is required.
  file {
    path    = "/etc/app/config.yaml"
    content = "debug: false\n"
    mode    = "0644"
    uid     = 1000
    gid     = 1000
  }

  symlink {
    path   = "/usr/local/bin/app"
    source = "/opt/app/bin/app"
    uid    = 1000 # optional
    gid    = 1000 # optional
  }
}
```

`destination` without a `/` is automatically prefixed with the provider's `organization`. Changing `name`, `source`, `destination` or `tag_definition_id` replaces the customization. See [docs/resources/customization.md](docs/resources/customization.md) for the full schema, including `file`, `symlink` and Helm chart customizations.

#### Inheritance and overriding

| Field | When you set it |
|-------|-----------------|
| `compression`, `entrypoint`, `cmd`, `working_directory` | Replaces the inherited value. |
| `environment`, `labels`, `annotations` | Merged by key: a key you set overrides the inherited key with the same name, other inherited keys are kept. |
| `accounts` | Each of `run_as` and `create_root_user` you set overrides the inherited one. Any `user` or `group` block replaces the inherited users or groups instead of adding to them. |
| `contents` | Additional packages and artifacts. Leave the block out to inherit. |
| `platforms` | Required: at least one platform. |

Removing a field from your configuration goes back to inheriting.

### Import a Customization

```bash
terraform import dhi_customization.golang <customization-id>
```

Import records only what the customization overrides. Anything it inherits is `null` in state, so write only the overridden fields in your configuration. Run `terraform plan` after the import: it should show no changes.

## 📄 License

See [LICENSE](LICENSE) for details. 

## 📬 Contact

For questions about the Terraform provider or Docker Hardened Images:
- Documentation: [Docker Hardened Images](https://www.docker.com/products/hardened-images/)

---

**Docker Hardened Images** — Building secure containers, together.
