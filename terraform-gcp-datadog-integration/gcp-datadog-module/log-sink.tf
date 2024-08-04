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

####################################################################
######## LOG SINKS CREATION AT THE PROJECT/FOLDER LEVEL  ###########
####################################################################

# Create a logging sink at the PROJECT scope | if variable 'log_sink_in_folder' is 'true' this resource will not be created.
resource "google_logging_project_sink" "datadog_export_sink" {
  count = var.log_sink_in_folder ? 0 : 1

  name                   = "datadog-export-sink"
  description            = "Project Sink to route logs from GCP to Datadog."
  project                = var.project_id
  destination            = "pubsub.googleapis.com/projects/${var.project_id}/topics/${var.topic_name}"
  unique_writer_identity = true
  filter                 = var.inclusion_filter
}

# Create a logging sink at the FOLDER scope | if variable 'log_sink_in_folder' is 'false' or not used this resource will not be created.
resource "google_logging_folder_sink" "datadog_export_sink" {
  count = var.log_sink_in_folder ? 1 : 0

  name             = "datadog-export-sink"
  description      = "Folder Sink to route logs from GCP to Datadog."
  folder           = var.folder_id
  destination      = "pubsub.googleapis.com/projects/${var.project_id}/topics/${var.topic_name}"
  filter           = var.inclusion_filter
  include_children = true
}

#########################################################################
# CREATE A BUCKET WITH A RANDOM ID NAME TO PUT DATAFLOW TEMPORARY FILES #
#########################################################################

resource "random_id" "random" {
  byte_length = 4
}

resource "google_storage_bucket" "temp_files_bucket" {
  name     = lower("${var.dataflow_temp_bucket_name}-${random_id.random.hex}")
  location = var.region

  uniform_bucket_level_access = true
  storage_class               = "STANDARD"
  public_access_prevention    = "enforced"
}