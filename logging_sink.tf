# ------------------------------------------------------------------------------
# Cloud Logging: Log Router Sink for Cloud Run
# ------------------------------------------------------------------------------

# Project-level log sink routing Cloud Run container logs to Pub/Sub
resource "google_logging_project_sink" "cloud_run_sink" {
  name        = "${var.resource_prefix}-sink"
  project     = var.project_id
  destination = "pubsub.googleapis.com/${module.logs_topic.topic_id}"
  filter      = local.final_log_filter

  # Enforce a dedicated service account identity for least-privilege topic publishing
  unique_writer_identity = true

  depends_on = [
    module.logs_topic,
    google_project_service.required_apis
  ]
}

# Grant the log sink's unique writer service account permission to publish to the logs topic
resource "google_pubsub_topic_iam_member" "sink_pubsub_publisher" {
  project = var.project_id
  topic   = module.logs_topic.topic_name
  role    = "roles/pubsub.publisher"
  member  = google_logging_project_sink.cloud_run_sink.writer_identity
}