resource "github_organization_ruleset" "protect_main" {
  name        = "Protect main"
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH", "refs/heads/main", "refs/heads/master"]
      exclude = []
    }
    repository_name {
      include = ["~ALL"]
      exclude = []
    }
  }

  rules {
    deletion         = true
    non_fast_forward = true
    update           = true
  }

  bypass_actors {
    actor_type  = "OrganizationAdmin"
    actor_id    = 1
    bypass_mode = "exempt"
  }

  bypass_actors {
    actor_type  = "RepositoryRole"
    actor_id    = 2
    bypass_mode = "exempt"
  }
}

resource "github_organization_ruleset" "protect_cicd" {
  name        = "Protect CI/CD"
  target      = "push"
  enforcement = "active"

  conditions {
    repository_name {
      include = ["~ALL"]
      exclude = []
    }
  }

  rules {
    file_path_restriction {
      restricted_file_paths = [".github/**/*"]
    }
  }

  bypass_actors {
    actor_type  = "OrganizationAdmin"
    actor_id    = 1
    bypass_mode = "always"
  }
}

resource "github_organization_ruleset" "forbid_binaries" {
  name        = "Forbid binaries"
  target      = "push"
  enforcement = "active"

  conditions {
    repository_name {
      include = ["~ALL"]
      exclude = []
    }
  }

  rules {
    file_path_restriction {
      restricted_file_paths = [
        "**/*.exe",
        "**/*.dll",
        "**/*.so",
        "**/*.lib",
        "**/*.a",
        "**/*.out",
      ]
    }
    max_file_size {
      max_file_size = 1
    }
  }

  bypass_actors {
    actor_type  = "OrganizationAdmin"
    actor_id    = 1
    bypass_mode = "always"
  }
}
