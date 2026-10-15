# ------------------------------------------------------------------------------
# Google Cloud Storage: Dataflow Staging & Temporary Storage
# ------------------------------------------------------------------------------
module "dataflow_bucket" {
  source     = "./modules/gcs"
  project_id = var.project_id
  location   = var.region
  name       = "${var.resource_prefix}-dataflow-${random_id.suffix.hex}"
  cors = [
    {
      origin          = ["*"]
      max_age_seconds = 3600
      method          = ["GET", "POST", "PUT", "DELETE"]
      response_header = ["*"]
    }
  ]
  versioning = true
  lifecycle_rules = [
    {
      condition = {
        age = 14
      }
      action = {
        type = "Delete"
      }
    },
    {
      condition = {
        age = 1
      }
      action = {
        type = "AbortIncompleteMultipartUpload"
      }
    }
  ]
  contents                    = []
  notifications               = []
  force_destroy               = var.storage_bucket_force_destroy
  uniform_bucket_level_access = true
  depends_on                  = [google_project_service.required_apis]
}

# Stage the JavaScript UDF to Cloud Storage for payload transformation & replay handling
resource "google_storage_bucket_object" "udf_transform" {
  count  = var.enable_udf ? 1 : 0
  name   = "udf/transform.js"
  bucket = module.dataflow_bucket.bucket_name
  source = "${path.module}/udf/transform.js"

  depends_on = [module.dataflow_bucket]
}

# Stage the JavaScript UDF to Cloud Storage for payload transformation & replay handling
resource "google_storage_bucket_object" "udf_transform" {
  count  = var.enable_udf ? 1 : 0
  name   = "udf/transform.js"
  bucket = module.dataflow_bucket.bucket_name
  source = "${path.module}/udf/transform.js"

  depends_on = [module.dataflow_bucket]
}