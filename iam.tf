# ------------------------------------------------------------------------------
# Identity & Access Management (IAM): Least-Privilege Dataflow Worker
# ------------------------------------------------------------------------------

# Dedicated service account for Dataflow worker VMs (used by primary & replay pipelines)
resource "google_service_account" "dataflow_worker" {
  account_id   = "${var.resource_prefix}-worker"
  display_name = "Dataflow Worker Service Account for Datadog Logs"
  description  = "Least-privilege identity used by Dataflow workers to stream Cloud Run logs to Datadog and replay failed messages"
  project      = var.project_id

  depends_on = [google_project_service.required_apis]
}

# 1. Base Dataflow Worker role (scoped to project)
resource "google_project_iam_member" "dataflow_worker_role" {
  project = var.project_id
  role    = "roles/dataflow.worker"
  member  = "serviceAccount:${google_service_account.dataflow_worker.email}"
}

# 2. Resource-level Pub/Sub Subscriber permission on the primary input subscription
resource "google_pubsub_subscription_iam_member" "worker_subscription_subscriber" {
  subscription = module.logs_topic.subscription_names["${var.resource_prefix}-logs-sub"]
  project      = var.project_id
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:${google_service_account.dataflow_worker.email}"
}

# 3. Resource-level Pub/Sub Viewer permission on the primary input subscription
resource "google_pubsub_subscription_iam_member" "worker_subscription_viewer" {
  subscription = module.logs_topic.subscription_names["${var.resource_prefix}-logs-sub"]
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
  bucket = module.dataflow_bucket.bucket_name
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

# ------------------------------------------------------------------------------
# IAM Permissions for Secondary (Replay) Pipeline
# ------------------------------------------------------------------------------

# 7. Resource-level Pub/Sub Subscriber permission on the DLQ subscription (for replaying failed messages)
resource "google_pubsub_subscription_iam_member" "worker_dlq_subscriber" {
  subscription = module.dlq_topic.subscription_names["${var.resource_prefix}-dlq-sub"]
  project      = var.project_id
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:${google_service_account.dataflow_worker.email}"
}

# 8. Resource-level Pub/Sub Viewer permission on the DLQ subscription (for replaying failed messages)
resource "google_pubsub_subscription_iam_member" "worker_dlq_viewer" {
  subscription = module.dlq_topic.subscription_names["${var.resource_prefix}-dlq-sub"]
  project      = var.project_id
  role         = "roles/pubsub.viewer"
  member       = "serviceAccount:${google_service_account.dataflow_worker.email}"
}

# 9. Resource-level Pub/Sub Publisher permission on the primary logs topic (to republish replayed messages)
resource "google_pubsub_topic_iam_member" "worker_logs_publisher" {
  topic   = module.logs_topic.topic_name
  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.dataflow_worker.email}"
}