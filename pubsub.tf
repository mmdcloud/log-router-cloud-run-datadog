# ------------------------------------------------------------------------------
# Google Cloud Pub/Sub: Ingestion & Dead-Letter Topics
# ------------------------------------------------------------------------------

# Main Pub/Sub topic receiving Cloud Run logs from Cloud Logging Sink
module "logs_topic" {
  source     = "./modules/pubsub"
  project_id = var.project_id
  topic_name = "${var.resource_prefix}-logs"

  subscriptions = {
    "${var.resource_prefix}-logs-sub" = {
      ack_deadline_seconds       = var.pubsub_ack_deadline_seconds
      message_retention_duration = var.pubsub_message_retention_duration
      retain_acked_messages      = false
      ttl                        = ""
    }
  }

  labels = var.labels

  depends_on = [google_project_service.required_apis]
}

# Dead-Letter Topic (DLQ) for unprocessable messages or failed delivery to Datadog
module "dlq_topic" {
  source     = "./modules/pubsub"
  project_id = var.project_id
  topic_name = "${var.resource_prefix}-dlq"

  subscriptions = {
    "${var.resource_prefix}-logs-sub" = {
      ack_deadline_seconds       = 60
      message_retention_duration = "604800s" # 7 days
      retain_acked_messages      = false
      ttl                        = ""
    }
  }

  labels     = var.labels
  
  depends_on = [google_project_service.required_apis]
}