# ------------------------------------------------------------------------------
# Google Cloud Dataflow: Pub/Sub to Datadog Streaming Pipeline
# ------------------------------------------------------------------------------
module "pubsub_to_datadog" {
  source                 = "./modules/dataflow/classic-template"
  name                   = var.dataflow_job_name != "" ? var.dataflow_job_name : "${var.resource_prefix}-stream"  
  template_gcs_path      = "gs://dataflow-templates/latest/Cloud_PubSub_to_Datadog"
  temp_gcs_location      = "gs://${google_storage_bucket.dataflow_bucket.name}/temp"
  service_account_email  = google_service_account.dataflow_worker.email
  machine_type           = var.dataflow_machine_type
  max_workers            = var.dataflow_max_workers
  on_delete              = var.dataflow_on_delete
  ip_configuration       = var.dataflow_worker_ip_configuration
  network                = var.dataflow_network != "" ? var.dataflow_network : null
  subnetwork             = var.dataflow_subnetwork != "" ? var.dataflow_subnetwork : null
  labels                 = var.labels
  additional_experiments = []

  # Template runtime parameters
  parameters = {
    inputSubscription     = google_pubsub_subscription.logs_sub.id
    outputDeadletterTopic = module.dlq_topic.topic_id
    url                   = local.datadog_intake_url
    apiKeySource          = "SECRET_MANAGER"
    apiKeySecretId        = local.effective_secret_version_id
    batchCount            = tostring(var.dataflow_batch_count)
    parallelism           = tostring(var.dataflow_parallelism)
    includePubsubMessage  = tostring(var.dataflow_include_pubsub_message)
  }

  # Ensure all least-privilege IAM bindings are active before launching the pipeline
  depends_on = [
    google_project_service.required_apis,
    google_project_iam_member.dataflow_worker_role,
    google_pubsub_subscription_iam_member.worker_subscription_subscriber,
    google_pubsub_subscription_iam_member.worker_subscription_viewer,
    google_pubsub_topic_iam_member.worker_dlq_publisher,
    google_storage_bucket_iam_member.worker_storage_admin,
    google_secret_manager_secret_iam_member.worker_secret_accessor
  ]
}