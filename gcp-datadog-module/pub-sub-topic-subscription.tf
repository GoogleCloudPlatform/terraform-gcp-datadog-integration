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

# Fetch project details
data "google_project" "project" {
  project_id = var.project_id
}

#######################################################
######### PUB/SUB TOPIC AND SUBSCRIPTION  #############
#######################################################

resource "google_pubsub_topic" "datadog_topic" {
  name    = "${local.resource_prefix}${var.topic_name}"
  project = var.project_id
  labels  = var.labels

  depends_on = [time_sleep.wait_for_apis]
}

resource "google_pubsub_subscription" "datadog_topic_sub" {
  ack_deadline_seconds = 10

  expiration_policy {
    ttl = "2678400s"
  }

  message_retention_duration = "604800s"
  name                       = "${local.resource_prefix}${var.subscription_name}"
  project                    = var.project_id
  topic                      = google_pubsub_topic.datadog_topic.id
}

###############################################################
######### TOPIC PERMISSIONS FOR THE LOG SINK IDENTITY #########
###############################################################

# Define IAM permissions for the Log Sink identity to publish logs to the topic (Sink at the PROJECT level)
resource "google_pubsub_topic_iam_member" "logs_sa_publishing_permissions" {
  count   = var.log_sink_in_folder ? 0 : 1
  project = var.project_id
  topic   = google_pubsub_topic.datadog_topic.id
  role    = "roles/pubsub.publisher"
  member  = google_logging_project_sink.datadog_export_sink[0].writer_identity
}

# Define IAM permissions for the Log Sink identity to publish logs to the topic (Sink at the FOLDER level)
resource "google_pubsub_topic_iam_member" "logs_sa_publishing_permissions_folder" {
  count   = var.log_sink_in_folder ? 1 : 0
  project = var.project_id
  topic   = google_pubsub_topic.datadog_topic.id
  role    = "roles/pubsub.publisher"
  member  = google_logging_folder_sink.datadog_export_sink[0].writer_identity
}

#########################################################
################## DEAD LETTER TOPIC  ###################
#########################################################

#This additional Topic/Subscription are created to handle any log messages rejected by the Datadog API.

resource "google_pubsub_topic" "output_dead_letter" {
  name    = "${local.resource_prefix}${var.topic_name}-deadletter"
  project = var.project_id
  labels  = var.labels
}

resource "google_pubsub_subscription" "output_dead_letter_sub" {
  ack_deadline_seconds = 10

  expiration_policy {
    ttl = "2678400s"
  }

  message_retention_duration = "604800s"
  name                       = "${local.resource_prefix}${var.subscription_name}-deadletter"
  project                    = var.project_id
  topic                      = google_pubsub_topic.output_dead_letter.id
}
