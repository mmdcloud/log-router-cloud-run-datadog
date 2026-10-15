# ------------------------------------------------------------------------------
# Google Cloud Dataflow: Primary Pipeline (Pub/Sub to Datadog)
# ------------------------------------------------------------------------------
module "pubsub_to_datadog" {
  source                 = "./modules/dataflow/classic-template"
  name                   = var.dataflow_job_name != "" ? var.dataflow_job_name : "${var.resource_prefix}-stream"
  template_gcs_path      = "gs://dataflow-templates/latest/Cloud_PubSub_to_Datadog"
  temp_gcs_location      = "gs://${module.dataflow_bucket.bucket_name}/temp"
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
  parameters = merge(
    {
      inputSubscription     = module.logs_topic.subscription_ids["${var.resource_prefix}-logs-sub"]
      outputDeadletterTopic = module.dlq_topic.topic_id
      url                   = local.datadog_intake_url
      apiKeySource          = "SECRET_MANAGER"
      apiKeySecretId        = local.effective_secret_version_id
      batchCount            = tostring(var.dataflow_batch_count)
      parallelism           = tostring(var.dataflow_parallelism)
      includePubsubMessage  = tostring(var.dataflow_include_pubsub_message)
    },
    var.enable_udf ? {
      javascriptTextTransformGcsPath      = "gs://${module.dataflow_bucket.bucket_name}/${google_storage_bucket_object.udf_transform[0].name}"
      javascriptTextTransformFunctionName = var.udf_function_name
    } : {}
  )

  # Ensure all least-privilege IAM bindings and staging bucket exist before launching
  depends_on = [
    google_project_service.required_apis,
    google_project_iam_member.dataflow_worker_role,
    google_pubsub_subscription_iam_member.worker_subscription_subscriber,
    google_pubsub_subscription_iam_member.worker_subscription_viewer,
    google_pubsub_topic_iam_member.worker_dlq_publisher,
    google_storage_bucket_iam_member.worker_storage_admin,
    google_secret_manager_secret_iam_member.worker_secret_accessor,
    google_storage_bucket_object.udf_transform
  ]
}

# ------------------------------------------------------------------------------
# Secondary (Backup) Dataflow Pipeline: Replay Failed Messages (Pub/Sub to Pub/Sub)
# ------------------------------------------------------------------------------
# Parallel to the primary pipeline, this moves failed messages from the DLQ
# subscription back to the main logs topic to replay messages once root cause
# is resolved. Controlled on-demand by var.deploy_replay_job.
module "replay_job" {
  count                  = var.deploy_replay_job ? 1 : 0
  source                 = "./modules/dataflow/classic-template"
  name                   = var.replay_job_name != "" ? var.replay_job_name : "${var.resource_prefix}-replay-stream"
  template_gcs_path      = "gs://dataflow-templates/latest/Cloud_PubSub_to_Cloud_PubSub"
  temp_gcs_location      = "gs://${module.dataflow_bucket.bucket_name}/temp-replay"
  service_account_email  = google_service_account.dataflow_worker.email
  machine_type           = var.replay_machine_type
  max_workers            = var.replay_max_workers
  on_delete              = var.replay_on_delete
  ip_configuration       = var.dataflow_worker_ip_configuration
  network                = var.dataflow_network != "" ? var.dataflow_network : null
  subnetwork             = var.dataflow_subnetwork != "" ? var.dataflow_subnetwork : null
  labels                 = var.labels
  additional_experiments = []

  # Template runtime parameters: Replay DLQ messages to original logs topic
  parameters = {
    inputSubscription = module.dlq_topic.subscription_ids["${var.resource_prefix}-dlq-sub"]
    outputTopic       = module.logs_topic.topic_id
  }

  depends_on = [
    google_project_service.required_apis,
    google_project_iam_member.dataflow_worker_role,
    google_pubsub_subscription_iam_member.worker_dlq_subscriber,
    google_pubsub_subscription_iam_member.worker_dlq_viewer,
    google_pubsub_topic_iam_member.worker_logs_publisher,
    google_storage_bucket_iam_member.worker_storage_admin
  ]
}
