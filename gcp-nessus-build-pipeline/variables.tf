variable "project" {
  description = "The project ID where all resources will be launched."
  type        = string
}

variable "location" {
  description = "The location (region or zone) of the GKE cluster."
  type        = string
}

variable "repository_name" {
  description = "Name of the Google Cloud Source Repository."
  type        = string
  default     = "example-repo"
}

variable "artifact_registry_name" {
  description = "Name of the Google Artifact Registry."
  type        = string
  default     = "nessus-builds"
}

variable "branch_name" {
  description = "Example branch name used to trigger builds."
  type        = string
  default     = "master"
}

variable "my_secret_data" {
  description = "Secret data to store in Secret Manager."
  type        = string
  default     = "super secret password"
  sensitive   = true
}

variable "admin_pass_secret_data" {
  description = "Secret data to store in Secret Manager."
  type        = string
  default     = "linking key secret password123"
  sensitive   = true
}
