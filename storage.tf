# ------------------------------------------------------------------------------
# Google Cloud Storage: Dataflow Staging & Temporary Storage
# ------------------------------------------------------------------------------
resource "google_storage_bucket" "dataflow_bucket" {
  name                        = "${var.resource_prefix}-dataflow-${random_id.suffix.hex}"
  project                     = var.project_id
  location                    = var.region
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = var.storage_bucket_force_destroy
  labels                      = var.labels

  versioning {
    enabled = true
  }

  # Automatically clean up temporary staging and pipeline files
  lifecycle_rule {
    condition {
      age = 14 # days
    }
    action {
      type = "Delete"
    }
  }

  # Abort incomplete multipart uploads after 1 day to prevent dangling storage costs
  lifecycle_rule {
    condition {
      age = 1
    }
    action {
      type = "AbortIncompleteMultipartUpload"
    }
  }

  depends_on = [google_project_service.required_apis]
}