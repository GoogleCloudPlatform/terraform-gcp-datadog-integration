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

output "dataflow_job_name" {
  description = "The name of the created Dataflow job."
  value       = google_dataflow_job.pubsub_stream_to_datadog.name
}

output "temp_files_bucket_name" {
  description = "The name of the created temporary files bucket."
  value       = google_storage_bucket.temp_files_bucket.name
}

output "datadog_topic_name" {
  description = "The name of the created Pub/Sub topic."
  value       = google_pubsub_topic.datadog_topic.name
}

output "datadog_subscription_name" {
  description = "The name of the created Pub/Sub subscription."
  value       = google_pubsub_subscription.datadog_topic_sub.name
}