# Plan only: apply would be followed by a destroy, which prevent_destroy refuses
mock_provider "truenas" {}

variables {
  root = "tank/app_data"

  images = {
    "debian/media" = {
      type = "media"
      storage = [
        { app = "media", dataset = "library", recordsize = "1M" },
        { app = "media", dataset = "config" },
      ]
    }
    "debian/media-worker" = {
      type    = "media-worker"
      storage = [{ app = "media", dataset = "library", recordsize = "1M" }]
    }
    "debian/plain" = {
      type = "plain"
    }
  }

  clients = {
    media  = { image = "debian/media", address = "192.0.2.20" }
    worker = { image = "debian/media-worker", address = "192.0.2.3" }
    plain  = { image = "debian/plain" }
  }
}

run "shares_per_dataset" {
  command = plan

  assert {
    condition     = keys(truenas_nfs_share.data) == ["media/config", "media/library"]
    error_message = "Expected one share per app and dataset pair."
  }

  assert {
    condition     = keys(truenas_dataset.app) == ["media"]
    error_message = "Expected one parent dataset per app."
  }

  assert {
    condition     = truenas_dataset.data["media/library"].name == "tank/app_data/media/library"
    error_message = "Dataset not under root/app."
  }

  assert {
    condition     = truenas_nfs_share.data["media/library"].hosts == tolist(["192.0.2.20", "192.0.2.3"])
    error_message = "Shared dataset must allow every client using it, sorted."
  }

  assert {
    condition     = truenas_nfs_share.data["media/library"].comment == "media, media-worker"
    error_message = "Comment must list the image types using the share."
  }

  assert {
    condition     = truenas_nfs_share.data["media/config"].hosts == tolist(["192.0.2.20"])
    error_message = "Unshared dataset must allow only its client."
  }

  assert {
    condition     = truenas_dataset.data["media/library"].recordsize == "1M"
    error_message = "recordsize must be set where given."
  }
}

run "no_storage_no_resources" {
  command = plan

  variables {
    clients = { plain = { image = "debian/plain" } }
  }

  assert {
    condition     = length(truenas_dataset.data) == 0 && length(truenas_nfs_share.data) == 0
    error_message = "A client whose image needs no storage must create nothing."
  }
}

run "recordsize_conflict" {
  command = plan

  variables {
    images = {
      "debian/a" = { type = "a", storage = [{ app = "app", dataset = "data", recordsize = "1M" }] }
      "debian/b" = { type = "b", storage = [{ app = "app", dataset = "data" }] }
    }
    clients = {
      a = { image = "debian/a", address = "192.0.2.1" }
      b = { image = "debian/b", address = "192.0.2.2" }
    }
  }

  expect_failures = [truenas_dataset.data]
}

run "client_without_address" {
  command = plan

  variables {
    clients = { media = { image = "debian/media" } }
  }

  expect_failures = [truenas_nfs_share.data]
}

run "unknown_image" {
  command = plan

  variables {
    clients = { other = { image = "debian/missing", address = "192.0.2.1" } }
  }

  expect_failures = [output.shares]
}

run "invalid_segment" {
  command = plan

  variables {
    images  = { "debian/a" = { type = "a", storage = [{ app = "../etc", dataset = "data" }] } }
    clients = { a = { image = "debian/a", address = "192.0.2.1" } }
  }

  expect_failures = [var.images]
}

run "invalid_address" {
  command = plan

  variables {
    clients = { media = { image = "debian/media", address = "192.0.2.20/24" } }
  }

  expect_failures = [var.clients]
}
