# ---------------------------------------------------------------------------
# Shared customization baseline module.
#
# Everything exposed here is image-agnostic: the same packages, accounts,
# environment, labels and files are applied to every image that consumes
# this module from the parent main.tf. Per-image values (source,
# destination, tag_definition_id, entrypoint, cmd, ...) are set there.
# ---------------------------------------------------------------------------

output "platforms" {
  value = ["linux/amd64", "linux/arm64"]
}

output "packages" {
  value = []
}

output "accounts" {
  value = {
    run_as           = "appuser"
    create_root_user = true

    users = [
      {
        name = "appuser"
        uid  = 1001
        gid  = 1001
      },
    ]

    groups = [
      {
        name    = "appgroup"
        gid     = 1001
        members = ["appuser"]
      },
    ]
  }
}

output "environment" {
  value = {
    APP_ENV   = "production"
    LOG_LEVEL = "info"
  }
}

output "labels" {
  value = {
    "com.example.managed-by"          = "terraform"
    "org.opencontainers.image.vendor" = "My Corp"
  }
}

output "annotations" {
  value = {
    "com.example.team" = "platform-engineering"
  }
}

output "files" {
  value = [
  ]
}
