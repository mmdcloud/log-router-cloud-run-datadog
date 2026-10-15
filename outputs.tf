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

output "pubsub_logs_subscription_name" {
  description = "The name of the primary Pub/Sub subscription consumed by Dataflow."
  value       = module.logs_topic.subscription_names["${var.resource_prefix}-logs-sub"]
}

output "pubsub_logs_subscription_id" {
  description = "The full resource ID of the primary Pub/Sub subscription consumed by Dataflow."
  value       = module.logs_topic.subscription_ids["${var.resource_prefix}-logs-sub"]
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
  description = "The name of the Pub/Sub subscription for inspecting and replaying DLQ messages."
  value       = module.dlq_topic.subscription_names["${var.resource_prefix}-dlq-sub"]
}

output "pubsub_dlq_subscription_id" {
  description = "The full resource ID of the Pub/Sub subscription for inspecting and replaying DLQ messages."
  value       = module.dlq_topic.subscription_ids["${var.resource_prefix}-dlq-sub"]
}

output "dataflow_job_id" {
  description = "The unique identifier of the primary Dataflow streaming job to Datadog."
  value       = module.pubsub_to_datadog.id
}

output "dataflow_job_name" {
  description = "The name of the primary Dataflow streaming job."
  value       = module.pubsub_to_datadog.name
}

output "dataflow_worker_service_account_email" {
  description = "The service account email assigned to Dataflow worker VMs."
  value       = google_service_account.dataflow_worker.email
}

output "dataflow_staging_bucket" {
  description = "The Cloud Storage bucket used for Dataflow temporary files and UDF staging."
  value       = module.dataflow_bucket.bucket_name
}

output "datadog_intake_url" {
  description = "The Datadog Logs intake URL receiving the events."
  value       = local.datadog_intake_url
}

output "datadog_secret_version_id" {
  description = "The Secret Manager secret version ID containing the Datadog API key."
  value       = local.effective_secret_version_id
}

output "udf_staging_location" {
  description = "The Cloud Storage URI of the staged JavaScript UDF for replay unnesting and transformation."
  value       = var.enable_udf ? "gs://${module.dataflow_bucket.bucket_name}/${google_storage_bucket_object.udf_transform[0].name}" : "disabled"
}

output "replay_job_deployed" {
  description = "Whether the secondary Dataflow replay pipeline is currently deployed."
  value       = var.deploy_replay_job
}

output "replay_dataflow_job_id" {
  description = "The unique identifier of the secondary replay Dataflow streaming job (if active)."
  value       = try(module.replay_job[0].id, null)
}

output "replay_dataflow_job_name" {
  description = "The name of the secondary replay Dataflow streaming job (if active)."
  value       = try(module.replay_job[0].name, null)
}
