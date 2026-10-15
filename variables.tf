variable "project_id" {
  type        = string
  description = "The Google Cloud Project ID where resources will be deployed."
}

variable "region" {
  type        = string
  default     = "us-central1"
  description = "The Google Cloud region for regional resources (Dataflow, GCS bucket, Pub/Sub)."
}

variable "resource_prefix" {
  type        = string
  default     = "cr-logs-dd"
  description = "Prefix applied to all created resource names for identification and consistency."
}

variable "labels" {
  type = map(string)
  default = {
    managed_by  = "terraform"
    environment = "production"
    integration = "datadog"
    workload    = "cloud-run-logs"
  }
  description = "Resource labels applied to supported resources (GCS, Pub/Sub, Dataflow, etc.)."
}

# ------------------------------------------------------------------------------
# Google Cloud Run Log Router Filter Configuration
# ------------------------------------------------------------------------------

variable "cloud_run_service_names" {
  type        = list(string)
  default     = []
  description = "Optional list of Cloud Run service names to filter. If empty, all Cloud Run revision logs are captured."
}

variable "include_cloud_run_jobs" {
  type        = bool
  default     = false
  description = "Whether to include Cloud Run Jobs (resource.type = 'cloud_run_job') in the log router sink."
}

variable "log_min_severity" {
  type        = string
  default     = "DEFAULT"
  description = "Minimum log severity to forward (e.g. DEFAULT, DEBUG, INFO, WARNING, ERROR, CRITICAL)."
  validation {
    condition     = contains(["DEFAULT", "DEBUG", "INFO", "NOTICE", "WARNING", "ERROR", "CRITICAL", "ALERT", "EMERGENCY"], var.log_min_severity)
    error_message = "log_min_severity must be one of: DEFAULT, DEBUG, INFO, NOTICE, WARNING, ERROR, CRITICAL, ALERT, EMERGENCY."
  }
}

variable "custom_log_filter" {
  type        = string
  default     = ""
  description = "Custom Cloud Logging query filter expression. If provided, overrides the automatically generated filter."
}

# ------------------------------------------------------------------------------
# Datadog Integration Configuration
# ------------------------------------------------------------------------------

variable "datadog_site" {
  type        = string
  default     = "datadoghq.com"
  description = "The Datadog site domain (e.g., datadoghq.com, datadoghq.eu, us3.datadoghq.com, us5.datadoghq.com, ap1.datadoghq.com)."
  validation {
    condition = contains([
      "datadoghq.com",
      "datadoghq.eu",
      "us3.datadoghq.com",
      "us5.datadoghq.com",
      "ap1.datadoghq.com",
      "ddog-gov.com"
    ], var.datadog_site)
    error_message = "datadog_site must be a valid Datadog domain (e.g. datadoghq.com, datadoghq.eu, us3.datadoghq.com, us5.datadoghq.com, ap1.datadoghq.com, ddog-gov.com)."
  }
}

variable "datadog_api_key" {
  type        = string
  default     = ""
  sensitive   = true
  description = "Datadog API Key. If provided, Terraform will store it in Google Secret Manager. Leave blank if existing_secret_version_id is specified."
}

variable "existing_secret_version_id" {
  type        = string
  default     = ""
  description = "Full resource name of an existing Secret Manager secret version containing the Datadog API key (e.g., projects/PROJECT_ID/secrets/SECRET_ID/versions/VERSION_ID or /versions/latest). If set, datadog_api_key will not create a new secret."
}

# ------------------------------------------------------------------------------
# Primary Dataflow Pipeline Configuration
# ------------------------------------------------------------------------------

variable "dataflow_job_name" {
  type        = string
  default     = ""
  description = "Custom Dataflow job name. Defaults to '<resource_prefix>-stream' if empty."
}

variable "dataflow_machine_type" {
  type        = string
  default     = "n1-standard-2"
  description = "Compute Engine machine type for Dataflow worker VMs."
}

variable "dataflow_max_workers" {
  type        = number
  default     = 4
  description = "Maximum number of Dataflow worker instances for autoscaling."
}

variable "dataflow_num_workers" {
  type        = number
  default     = 1
  description = "Initial number of Dataflow worker instances."
}

variable "dataflow_batch_count" {
  type        = number
  default     = 100
  description = "Number of events bundled into a single HTTP POST request to Datadog."
}

variable "dataflow_parallelism" {
  type        = number
  default     = 1
  description = "Maximum number of parallel HTTP worker requests to Datadog."
}

variable "dataflow_include_pubsub_message" {
  type        = bool
  default     = true
  description = "Whether to include full Pub/Sub message metadata (attributes, publishTime) in the payload sent to Datadog."
}

variable "dataflow_worker_ip_configuration" {
  type        = string
  default     = "WORKER_IP_PUBLIC"
  description = "IP address configuration for Dataflow worker VMs. Set to 'WORKER_IP_PRIVATE' if workers run in a VPC with Cloud NAT enabled (recommended for hardened enterprise VPCs)."
  validation {
    condition     = contains(["WORKER_IP_PUBLIC", "WORKER_IP_PRIVATE"], var.dataflow_worker_ip_configuration)
    error_message = "dataflow_worker_ip_configuration must be either 'WORKER_IP_PUBLIC' or 'WORKER_IP_PRIVATE'."
  }
}

variable "dataflow_network" {
  type        = string
  default     = ""
  description = "VPC network to host Dataflow worker VMs. If empty, the default network is used."
}

variable "dataflow_subnetwork" {
  type        = string
  default     = ""
  description = "Subnetwork to host Dataflow worker VMs (required if dataflow_worker_ip_configuration is WORKER_IP_PRIVATE). Expected format: 'regions/<region>/subnetworks/<subnetwork-name>' or subnetwork URI."
}

variable "dataflow_on_delete" {
  type        = string
  default     = "drain"
  description = "Action when deleting the Dataflow job: 'drain' (recommended for production to prevent data loss) or 'cancel'."
  validation {
    condition     = contains(["drain", "cancel"], var.dataflow_on_delete)
    error_message = "dataflow_on_delete must be either 'drain' or 'cancel'."
  }
}

# ------------------------------------------------------------------------------
# UDF (User-Defined Function) Configuration
# ------------------------------------------------------------------------------

variable "enable_udf" {
  type        = bool
  default     = true
  description = "Whether to deploy and attach the JavaScript UDF to decode replayed messages and tally delivery attempts as recommended in the Google architecture reference."
}

variable "udf_function_name" {
  type        = string
  default     = "process"
  description = "Name of the JavaScript UDF function inside the transform script."
}

# ------------------------------------------------------------------------------
# Secondary (Backup / Replay) Pipeline Configuration
# ------------------------------------------------------------------------------

variable "deploy_replay_job" {
  type        = bool
  default     = false
  description = "Whether to deploy the secondary Dataflow replay pipeline (Pub/Sub to Pub/Sub) to move failed messages from the DLQ subscription back to the main logs topic."
}

variable "replay_job_name" {
  type        = string
  default     = ""
  description = "Custom name for the Dataflow replay pipeline. Defaults to '<resource_prefix>-replay-stream' if empty."
}

variable "replay_machine_type" {
  type        = string
  default     = "n1-standard-2"
  description = "Machine type for the Dataflow replay worker VMs."
}

variable "replay_max_workers" {
  type        = number
  default     = 2
  description = "Maximum number of worker instances for the replay pipeline."
}

variable "replay_on_delete" {
  type        = string
  default     = "drain"
  description = "Action when deleting the replay Dataflow job: 'drain' or 'cancel'."
  validation {
    condition     = contains(["drain", "cancel"], var.replay_on_delete)
    error_message = "replay_on_delete must be either 'drain' or 'cancel'."
  }
}

# ------------------------------------------------------------------------------
# Storage & Pub/Sub Configuration
# ------------------------------------------------------------------------------

variable "storage_bucket_force_destroy" {
  type        = bool
  default     = false
  description = "Whether to allow destroying the Dataflow staging/temp GCS bucket even if it contains objects."
}

variable "pubsub_message_retention_duration" {
  type        = string
  default     = "604800s" # 7 days
  description = "Message retention duration for the primary Pub/Sub subscription (e.g. 604800s for 7 days)."
}

variable "pubsub_ack_deadline_seconds" {
  type        = number
  default     = 60
  description = "Pub/Sub message acknowledgment deadline in seconds."
}

variable "enable_required_apis" {
  type        = bool
  default     = true
  description = "Whether Terraform should automatically enable required GCP APIs (logging, pubsub, dataflow, storage, secretmanager)."
}

# ------------------------------------------------------------------------------
# Cloud Run & Artifact Registry Configuration (Optional Service Deployment)
# ------------------------------------------------------------------------------

variable "location" {
  type        = string
  default     = "us-central1"
  description = "Location for Cloud Run and Artifact Registry resources."
}

variable "artifact_type" {
  type        = string
  default     = "DOCKER"
  description = "Format of packages stored in Artifact Registry."
}

variable "artifact_repository_description" {
  type        = string
  default     = "Docker repository for Cloud Run services"
  description = "Description for Artifact Registry repository."
}

variable "artifact_repository_id" {
  type        = string
  default     = "cloud-run-repo"
  description = "ID of the Artifact Registry repository."
}

variable "run_image_push_script" {
  type        = string
  default     = "scripts/build_and_push.sh"
  description = "Relative path to local image build/push script."
}

variable "cloud_run_sa_account_id" {
  type        = string
  default     = "cloud-run-sa"
  description = "Service account ID for Cloud Run service."
}

variable "cloud_run_sa_display_name" {
  type        = string
  default     = "Cloud Run Service Account"
  description = "Display name for Cloud Run service account."
}

variable "cloud_run_sa_permissions" {
  type        = list(string)
  default     = ["roles/logging.logWriter"]
  description = "List of IAM roles granted to Cloud Run service account."
}

variable "neg_name" {
  type        = string
  default     = "cloud-run-neg"
  description = "Name of the Serverless Network Endpoint Group."
}

variable "cloud_run_deletion_protection" {
  type        = bool
  default     = false
  description = "Whether deletion protection is enabled on Cloud Run."
}

variable "cloud_run_ingress" {
  type        = string
  default     = "INGRESS_TRAFFIC_ALL"
  description = "Ingress settings for Cloud Run."
}

variable "cloud_run_min_instance_count" {
  type        = number
  default     = 0
  description = "Minimum instances for Cloud Run."
}

variable "cloud_run_max_instance_count" {
  type        = number
  default     = 5
  description = "Maximum instances for Cloud Run."
}

variable "cloud_run_max_instance_request_concurrency" {
  type        = number
  default     = 80
  description = "Max concurrent requests per Cloud Run instance."
}

variable "cloud_run_service_name" {
  type        = string
  default     = "sample-cloud-run-app"
  description = "Cloud Run service name."
}

variable "cloud_run_container_port" {
  type        = number
  default     = 8080
  description = "Port exposed by Cloud Run container."
}

variable "cloud_run_env" {
  type        = any
  default     = []
  description = "Environment variables for Cloud Run container."
}

variable "cloud_run_cpu_idle" {
  type        = bool
  default     = true
  description = "Whether CPU is throttled when not serving requests."
}

variable "cloud_run_startup_cpu_boost" {
  type        = bool
  default     = false
  description = "Whether startup CPU boost is enabled."
}

variable "cloud_run_image_tag" {
  type        = string
  default     = "latest"
  description = "Docker image tag for Cloud Run."
}

variable "cloud_run_invoker_members" {
  type        = list(string)
  default     = ["allUsers"]
  description = "Members allowed to invoke Cloud Run service."
}
