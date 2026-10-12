output "log_sink_name" {
  description = "The name of the Cloud Logging Log Router Sink."
  value       = google_logging_project_sink.cloud_run_sink.name
}

output "log_sink_writer_identity" {
  description = "The unique writer identity service account generated for the Log Sink."
  value       = google_logging_project_sink.cloud_run_sink.writer_identity
}

output "log_sink_filter" {
  description = "The active filter query string routing Cloud Run logs to Pub/Sub."
  value       = local.final_log_filter
}

output "pubsub_logs_topic_name" {
  description = "The name of the Pub/Sub topic receiving Cloud Run logs."
  value       = module.logs_topic.topic_name
}

output "pubsub_logs_topic_id" {
  description = "The full resource ID of the Pub/Sub logs topic."
  value       = module.logs_topic.topic_id
}

output "pubsub_logs_subscription_id" {
  description = "The Pub/Sub subscription ID consumed by Dataflow."
  value       = google_pubsub_subscription.logs_sub.id
}

output "pubsub_dlq_topic_name" {
  description = "The name of the Dead-Letter Queue (DLQ) Pub/Sub topic."
  value       = module.dlq_topic.topic_name
}

output "pubsub_dlq_topic_id" {
  description = "The full resource ID of the Dead-Letter Queue (DLQ) Pub/Sub topic."
  value       = module.dlq_topic.topic_id
}

output "pubsub_dlq_subscription_name" {
  description = "The name of the Pub/Sub subscription for inspecting DLQ messages."
  value       = google_pubsub_subscription.dlq_sub.name
}

output "dataflow_job_id" {
  description = "The unique identifier of the Dataflow streaming job."
  value       = google_dataflow_job.pubsub_to_datadog.id
}

output "dataflow_job_name" {
  description = "The name of the Dataflow streaming job."
  value       = google_dataflow_job.pubsub_to_datadog.name
}

output "dataflow_worker_service_account_email" {
  description = "The service account email assigned to Dataflow worker VMs."
  value       = google_service_account.dataflow_worker.email
}

output "dataflow_staging_bucket" {
  description = "The Cloud Storage bucket used for Dataflow temporary files."
  value       = name.dataflow_bucket.bucket_name
}

output "datadog_intake_url" {
  description = "The Datadog Logs intake URL receiving the events."
  value       = local.datadog_intake_url
}

output "datadog_secret_version_id" {
  description = "The Secret Manager secret version ID containing the Datadog API key."
  value       = local.effective_secret_version_id
}
