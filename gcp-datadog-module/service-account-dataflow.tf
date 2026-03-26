# Copyright 2024 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Create a Google Service Account for Dataflow service to fulfill the log export to Datadog.
resource "google_service_account" "dataflow_datadog_export_sa" {
  account_id   = "${local.resource_prefix}dataflow-export-sa"
  display_name = "Dataflow Service Account"
  description  = "Service account used by the Dataflow service to export logs to Datadog."
  project      = var.project_id
  depends_on   = [time_sleep.wait_for_apis]
}

# Project-level IAM roles (only those that cannot be scoped to a specific resource)
resource "google_project_iam_member" "dataflow_datadog_sa_roles" {
  project = var.project_id
  for_each = toset([
    "roles/dataflow.worker",
  ])
  role   = each.key
  member = "serviceAccount:${google_service_account.dataflow_datadog_export_sa.email}"
}

# Scoped: Pub/Sub Subscriber + Viewer on the main subscription
resource "google_pubsub_subscription_iam_member" "dataflow_subscriber" {
  project      = var.project_id
  subscription = google_pubsub_subscription.datadog_topic_sub.name
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:${google_service_account.dataflow_datadog_export_sa.email}"
}

resource "google_pubsub_subscription_iam_member" "dataflow_viewer" {
  project      = var.project_id
  subscription = google_pubsub_subscription.datadog_topic_sub.name
  role         = "roles/pubsub.viewer"
  member       = "serviceAccount:${google_service_account.dataflow_datadog_export_sa.email}"
}

# Scoped: Pub/Sub Publisher on the dead-letter topic
resource "google_pubsub_topic_iam_member" "dataflow_deadletter_publisher" {
  project = var.project_id
  topic   = google_pubsub_topic.output_dead_letter.name
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.dataflow_datadog_export_sa.email}"
}

# Scoped: Secret Manager accessor on the Datadog API key secret
resource "google_secret_manager_secret_iam_member" "dataflow_secret_accessor" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.datadog_secret.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.dataflow_datadog_export_sa.email}"
}

# Scoped: Storage Object Admin on the temp files bucket
resource "google_storage_bucket_iam_member" "dataflow_storage_admin" {
  bucket = google_storage_bucket.temp_files_bucket.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.dataflow_datadog_export_sa.email}"
}
