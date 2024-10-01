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

#####################################################################
# CREATE A DATAFLOW JOB THAT USES THE 'PUB/SUB TO DATADOG' TEMPLATE #
#####################################################################

resource "google_dataflow_job" "pubsub_stream_to_datadog" {
  name                    = var.dataflow_job_name
  template_gcs_path       = "gs://dataflow-templates-${var.subnet_region}/latest/Cloud_PubSub_to_Datadog"
  temp_gcs_location       = "gs://${google_storage_bucket.temp_files_bucket.id}/tmp_dir"
  region                  = var.subnet_region
  service_account_email   = google_service_account.dataflow_datadog_export_sa.email
  network                 = data.google_compute_network.vpc.name
  subnetwork              = data.google_compute_subnetwork.dataflow_subnetwork.self_link
  ip_configuration        = "WORKER_IP_PRIVATE"
  max_workers             = 3
  enable_streaming_engine = true
  parameters = {
    inputSubscription     = google_pubsub_subscription.datadog_topic_sub.id,
    url                   = var.datadog_site_url,
    apiKeySecretId        = google_secret_manager_secret_version.secret_version.name,
    apiKeySource          = "SECRET_MANAGER",
    outputDeadletterTopic = google_pubsub_topic.output_dead_letter.id
  }
  on_delete = "cancel"
  labels    = { dataflow-job-label = "datadog_terraform" }
  depends_on = [google_project_service.enable_apis, time_sleep.dataflow_sa_creation]
}