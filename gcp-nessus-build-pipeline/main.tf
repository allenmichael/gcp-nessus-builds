provider "google-beta" {
  project = var.project # replace with your project ID
}
provider "google" {
  project = var.project
}

resource "google_project_service_identity" "cb_sa" {
  provider = google-beta
  service  = "cloudbuild.googleapis.com"
}

resource "google_project_service" "secretmanager" {
  provider = google-beta
  service  = "secretmanager.googleapis.com"
}

resource "google_secret_manager_secret" "linking-key-secret" {
  provider = google-beta

  secret_id = "LINKING_KEY"

  replication {
    automatic = true
  }

  depends_on = [google_project_service.secretmanager]
}

resource "google_secret_manager_secret_version" "linking-key-secret-1" {
  provider = google-beta

  secret      = google_secret_manager_secret.linking-key-secret.id
  secret_data = var.my_secret_data
}

resource "google_secret_manager_secret_iam_member" "cloud-build-access-linking-key" {
  provider = google-beta

  secret_id = google_secret_manager_secret.linking-key-secret.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_project_service_identity.cb_sa.email}"
}
resource "google_secret_manager_secret" "admin-pass-key-secret" {
  provider = google-beta

  secret_id = "ADMIN_PASS"

  replication {
    automatic = true
  }

  depends_on = [google_project_service.secretmanager]
}

resource "google_secret_manager_secret_version" "admin-pass-secret-1" {
  provider = google-beta

  secret      = google_secret_manager_secret.admin-pass-key-secret.id
  secret_data = var.admin_pass_secret_data
}

resource "google_secret_manager_secret_iam_member" "cloud-build-access-admin-pass" {
  provider = google-beta

  secret_id = google_secret_manager_secret.admin-pass-key-secret.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_project_service_identity.cb_sa.email}"
}

resource "google_artifact_registry_repository" "my-repo" {
  provider = google-beta

  location      = var.location
  repository_id = var.artifact_registry_name
  description   = "example docker repository"
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
  depends_on = [google_sourcerepo_repository.repo, google_artifact_registry_repository.my-repo]
}
