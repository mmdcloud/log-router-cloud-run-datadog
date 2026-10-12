# ------------------------------------------------------------------------------
# Google Secret Manager: Datadog API Key Management
# ------------------------------------------------------------------------------

# Create a Secret Manager secret for the Datadog API key if not referencing an existing secret
resource "google_secret_manager_secret" "datadog_api_key" {
  count     = var.existing_secret_version_id == "" ? 1 : 0
  secret_id = "${var.resource_prefix}-api-key"
  project   = var.project_id
  labels    = var.labels

  replication {
    auto {}
  }

  depends_on = [google_project_service.required_apis]
}

# Store the API key version payload in Secret Manager
resource "google_secret_manager_secret_version" "datadog_api_key" {
  count       = var.existing_secret_version_id == "" ? 1 : 0
  secret      = google_secret_manager_secret.datadog_api_key[0].id
  secret_data = var.datadog_api_key
}

locals {
  # Resolved Secret Version resource name to supply to the Dataflow template
  # Expected format: projects/<project-id>/secrets/<secret-id>/versions/<version-id>
  effective_secret_version_id = (
    var.existing_secret_version_id != ""
    ? var.existing_secret_version_id
    : google_secret_manager_secret_version.datadog_api_key[0].name
  )

  # Resolved Secret ID for IAM binding
  effective_secret_id = (
    var.existing_secret_version_id != ""
    ? split("/versions/", var.existing_secret_version_id)[0]
    : google_secret_manager_secret.datadog_api_key[0].id
  )
}