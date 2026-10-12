# ------------------------------------------------------------------------------
# Identity & Access Management (IAM): Least-Privilege Dataflow Worker
# ------------------------------------------------------------------------------

# Dedicated service account for Dataflow worker VMs
resource "google_service_account" "dataflow_worker" {
  account_id   = "${var.resource_prefix}-worker"
  display_name = "Dataflow Worker Service Account for Datadog Logs"
  description  = "Least-privilege identity used by Dataflow workers to stream Cloud Run logs to Datadog"
  project      = var.project_id

  depends_on = [google_project_service.required_apis]
}

# 1. Base Dataflow Worker role (scoped to project)
resource "google_project_iam_member" "dataflow_worker_role" {
  project = var.project_id
  role    = "roles/dataflow.worker"
  member  = "serviceAccount:${google_service_account.dataflow_worker.email}"
}

# 2. Resource-level Pub/Sub Subscriber permission on the input subscription
resource "google_pubsub_subscription_iam_member" "worker_subscription_subscriber" {
  subscription = google_pubsub_subscription.logs_sub.name
  project      = var.project_id
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:${google_service_account.dataflow_worker.email}"
}

# 3. Resource-level Pub/Sub Viewer permission on the input subscription
resource "google_pubsub_subscription_iam_member" "worker_subscription_viewer" {
  subscription = google_pubsub_subscription.logs_sub.name
  project      = var.project_id
  role         = "roles/pubsub.viewer"
  member       = "serviceAccount:${google_service_account.dataflow_worker.email}"
}

# 4. Resource-level Pub/Sub Publisher permission on the Dead-Letter Queue (DLQ) topic
resource "google_pubsub_topic_iam_member" "worker_dlq_publisher" {
  topic   = module.dlq_topic.topic_name
  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.dataflow_worker.email}"
}

# 5. Bucket-level Storage Object Admin permission on the Dataflow temp/staging bucket
resource "google_storage_bucket_iam_member" "worker_storage_admin" {
  bucket = name.dataflow_bucket.bucket_name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.dataflow_worker.email}"
}

# 6. Secret-level Secret Accessor permission on the Datadog API Key secret
resource "google_secret_manager_secret_iam_member" "worker_secret_accessor" {
  secret_id = local.effective_secret_id
  project   = var.project_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.dataflow_worker.email}"
}