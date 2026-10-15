output "id" {
  description = "The unique identifier of the Dataflow job."
  value       = google_dataflow_job.job.id
}

output "job_id" {
  description = "The unique identifier of the Dataflow job."
  value       = google_dataflow_job.job.id
}

output "name" {
  description = "The name of the Dataflow job."
  value       = google_dataflow_job.job.name
}

output "job_name" {
  description = "The name of the Dataflow job."
  value       = google_dataflow_job.job.name
}

output "state" {
  description = "The current state of the Dataflow job."
  value       = google_dataflow_job.job.state
}