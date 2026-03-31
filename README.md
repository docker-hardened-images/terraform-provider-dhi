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

```hcl
locals {
  dev_tag = one([
    for td in data.dhi_catalog_repository.golang.tag_definitions :
    td if contains(td.tag_names, "1-dev")
  ])
}

resource "dhi_customization" "golang" {
  name              = "custom"
  source            = "dhi/golang"
  destination       = dhi_mirror.golang.destination_name
  tag_definition_id = local.dev_tag.id

  platforms = ["linux/amd64", "linux/arm64"]

  contents {
    packages = ["curl", "git", "jq"]
  }

  accounts {
    run_as           = "nonroot"
    create_root_user = false

    user {
      name = "nonroot"
      uid  = 65532
    }
  }

  entrypoint = ["/usr/local/bin/go"]
}
```

`destination` without a `/` is automatically prefixed with the provider's `organization`.

## 📄 License

See [LICENSE](LICENSE) for details.

## 📬 Contact

For questions about the Terraform provider or Docker Hardened Images:
- Documentation: [Docker Hardened Images](https://www.docker.com/products/hardened-images/)

---

**Docker Hardened Images** — Building secure containers, together.
