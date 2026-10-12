#---------------------------------------------------------------
# Artifact Registry
#---------------------------------------------------------------
module "artifact_registry" {
  source        = "./modules/artifact-registry"
  project_id    = var.project_id
  location      = var.location
  artifact_type = var.artifact_type
  description   = var.artifact_repository_description
  repository_id = var.artifact_repository_id

  depends_on = [google_project_service.apis]
}

resource "null_resource" "build_and_push_image" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "bash ${path.cwd}/${var.run_image_push_script} ${data.google_project.project.project_id}"
  }

  depends_on = [
    module.artifact_registry
  ]
}

#---------------------------------------------------------------
# Cloud Run Service
#---------------------------------------------------------------
module "cloud_run_service_account" {
  source        = "./modules/service-account"
  account_id    = var.cloud_run_sa_account_id
  display_name  = var.cloud_run_sa_display_name
  project_id    = data.google_project.project.project_id
  member_prefix = "serviceAccount"
  permissions   = var.cloud_run_sa_permissions
}

module "service_neg" {
  source     = "./modules/network_endpoint_groups/serverless_neg"
  project_id = var.project_id
  neg_name   = var.neg_name
  region     = var.location
  cloud_run = {
    service = module.cloud_run_service.service_name
  }
}

module "cloud_run_service" {
  source                           = "./modules/cloud-run"
  project_id                       = var.project_id
  type                             = "SERVICE"
  deletion_protection              = var.cloud_run_deletion_protection
  ingress                          = var.cloud_run_ingress
  service_account                  = module.cloud_run_service_account.sa_email
  location                         = var.location
  min_instance_count               = var.cloud_run_min_instance_count
  max_instance_count               = var.cloud_run_max_instance_count
  max_instance_request_concurrency = var.cloud_run_max_instance_request_concurrency
  name                             = var.cloud_run_service_name
  volumes                          = []

  traffic = [
    {
      traffic_type         = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
      traffic_type_percent = 100
    }
  ]

  containers = [
    {
      port              = var.cloud_run_container_port
      env               = var.cloud_run_env
      volume_mounts     = []
      cpu_idle          = var.cloud_run_cpu_idle
      startup_cpu_boost = var.cloud_run_startup_cpu_boost
      image             = "${var.location}-docker.pkg.dev/${data.google_project.project.project_id}/${var.artifact_repository_id}/${var.cloud_run_service_name}:${var.cloud_run_image_tag}"
    }
  ]

  depends_on = [null_resource.build_and_push_image]
}

resource "google_cloud_run_v2_service_iam_member" "cloud_run_access" {
  for_each = toset(var.cloud_run_invoker_members)
  name     = module.cloud_run_service.service_name
  location = var.location
  project  = var.project_id
  role     = "roles/run.invoker"
  member   = each.key
}