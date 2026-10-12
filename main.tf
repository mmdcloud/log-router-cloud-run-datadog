# Generate a random suffix for globally unique resources (e.g. GCS bucket names)
resource "random_id" "suffix" {
  byte_length = 4
}

locals {
  # Datadog intake URL based on chosen site
  datadog_intake_url = "https://http-intake.logs.${var.datadog_site}"

  # Name prefixes and identifiers
  base_name = "${var.resource_prefix}-${var.region}"

  # Cloud Run Resource Filter Construction
  # Matches Cloud Run revisions (and optionally jobs), specific services, and severity levels
  default_resource_types = var.include_cloud_run_jobs ? [
    "resource.type = \"cloud_run_revision\"",
    "resource.type = \"cloud_run_job\""
    ] : [
    "resource.type = \"cloud_run_revision\""
  ]

  resource_type_filter = "(${join(" OR ", local.default_resource_types)})"

  service_filter = length(var.cloud_run_service_names) > 0 ? (
    "resource.labels.service_name = (${join(" OR ", [for s in var.cloud_run_service_names : "\"${s}\""])})"
  ) : ""

  severity_filter = var.log_min_severity != "DEFAULT" ? "severity >= ${var.log_min_severity}" : ""

  # Combine filter clauses
  computed_filter_clauses = compact([
    local.resource_type_filter,
    local.service_filter,
    local.severity_filter
  ])

  final_log_filter = var.custom_log_filter != "" ? var.custom_log_filter : join("\nAND ", local.computed_filter_clauses)
}

# ------------------------------------------------------------------------------
# Required Google Cloud APIs
# ------------------------------------------------------------------------------
resource "google_project_service" "required_apis" {
  for_each = var.enable_required_apis ? toset([
    "logging.googleapis.com",
    "pubsub.googleapis.com",
    "dataflow.googleapis.com",
    "storage.googleapis.com",
    "secretmanager.googleapis.com",
    "compute.googleapis.com"
  ]) : toset([])

  project            = var.project_id
  service            = each.key
  disable_on_destroy = false
}
