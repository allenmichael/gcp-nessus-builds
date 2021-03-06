provider "google-beta" {
  project = var.project # replace with your project ID
}
provider "google" {
  project = var.project
}

resource "google_project_service_identity" "cloudbuild" {
  provider = google-beta
  service  = "cloudbuild.googleapis.com"
}

resource "google_secret_manager_secret" "license-secret" {
  provider = google-beta

  secret_id = "license"

  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret_version" "license-secret-1" {
  provider = google-beta

  secret      = google_secret_manager_secret.license-secret.id
  secret_data = var.license_secret_data
}

resource "google_secret_manager_secret_iam_member" "cloud-build-access-linking-key" {
  provider = google-beta

  secret_id = google_secret_manager_secret.license-secret.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_project_service_identity.cloudbuild.email}"
}

resource "google_secret_manager_secret" "admin-pass-key-secret" {
  provider = google-beta

  secret_id = "adminpass"

  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret_version" "admin-pass-secret-1" {
  provider = google-beta

  secret      = google_secret_manager_secret.admin-pass-key-secret.id
  secret_data = var.admin_pass_secret_data
  enabled = true
}

resource "google_secret_manager_secret_iam_member" "cloud-build-access-admin-pass" {
  provider = google-beta

  secret_id = google_secret_manager_secret.admin-pass-key-secret.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_project_service_identity.cloudbuild.email}"
}

resource "google_artifact_registry_repository" "artifact-repo" {
  provider = google-beta

  location      = var.location
  repository_id = var.artifact_registry_name
  description   = "Nessus Build Docker repository"
  format        = "DOCKER"
}

resource "google_sourcerepo_repository" "repo" {
  name = var.repository_name
}

resource "google_cloudbuild_trigger" "cloud_build_trigger" {
  provider    = google-beta
  description = "Cloud Source Repository Trigger ${var.repository_name} (${var.branch_name})"

  trigger_template {
    branch_name = var.branch_name
    repo_name   = var.repository_name
  }

  filename   = "cloudbuild.yaml"
  depends_on = [google_sourcerepo_repository.repo, google_artifact_registry_repository.artifact-repo]
}
