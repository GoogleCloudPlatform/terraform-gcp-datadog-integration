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
  account_id   = "dataflow-datadog-export-sa"
  display_name = "Dataflow Service Account"
  description  = "Service account used by the Dataflow service to export logs to Datadog."
  project      = var.project_id
}

# Define IAM roles needed for the Dataflow Service Account
resource "google_project_iam_member" "dataflow_datadog_sa_roles" {
  project = var.project_id
  for_each = toset([
    "roles/dataflow.admin",
    "roles/dataflow.worker",
    "roles/pubsub.viewer",
    "roles/pubsub.subscriber",
    "roles/pubsub.publisher",
    "roles/secretmanager.secretAccessor",
    "roles/storage.objectAdmin"
  ])
  role   = each.key
  member = "serviceAccount:${google_service_account.dataflow_datadog_export_sa.email}"
}
