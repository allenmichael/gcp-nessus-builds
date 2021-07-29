variable "project" {
  description = "The project ID where all resources will be launched."
  type        = string
}

variable "location" {
  description = "The location to use."
  type        = string
  default     = "us-central1"
}

variable "repository_name" {
  description = "Name of the Google Cloud Source Repository."
  type        = string
  default     = "nessus-docker"
}

variable "artifact_registry_name" {
  description = "Name of the Google Artifact Registry."
  type        = string
  default     = "nessus-builds"
}

variable "branch_name" {
  description = "Example branch name used to trigger builds."
  type        = string
  default     = "main"
}

variable "license_secret_data" {
  description = "Secret data to store in Secret Manager."
  type        = string
  sensitive   = true
}

variable "admin_pass_secret_data" {
  description = "Secret data to store in Secret Manager."
  type        = string
  sensitive   = true
}
