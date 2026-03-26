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

##############################################################################
# Project Configuration
##############################################################################

variable "name_prefix" {
  type        = string
  description = "Prefix for all resource names to avoid collisions when deploying multiple instances in the same project. Set to empty string to disable prefixing."
  default     = "datadog"
  validation {
    condition     = var.name_prefix == "" || can(regex("^[a-z][a-z0-9-]{0,9}$", var.name_prefix))
    error_message = "The name prefix must be empty or start with a lowercase letter, contain only lowercase letters, numbers, and hyphens, and be at most 10 characters."
  }
}

variable "project_id" {
  type        = string
  description = "The ID of the Google Cloud project."
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "The project ID must be between 6 and 30 characters, start with a letter, end with a letter or number, and consist only of lowercase letters, numbers, and hyphens."
  }
}

variable "labels" {
  type        = map(string)
  description = "A map of labels to apply to all resources that support labels."
  default     = {}
}

variable "enabled_apis" {
  type        = list(string)
  description = "List of GCP APIs to enable for the Datadog integration."
  default = [
    "secretmanager.googleapis.com",
    "pubsub.googleapis.com",
    "dataflow.googleapis.com",
    "logging.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
    "serviceusage.googleapis.com"
  ]
}

variable "disable_on_destroy" {
  type        = bool
  description = "Whether to disable the APIs when destroying the module."
  default     = false
}

variable "disable_dependent_services" {
  type        = bool
  description = "Whether to disable dependent services when destroying the module."
  default     = false
}

##############################################################################
# Network Configuration
##############################################################################

variable "vpc_name" {
  type        = string
  description = "Name of the VPC used for Dataflow Virtual Machines."
}

variable "subnet_name" {
  type        = string
  description = "Name of the subnets used for Dataflow Virtual Machines."
}

variable "subnet_region" {
  type        = string
  description = "Region of the existing subnet, all the resources will be created in this region."
}

variable "create_cloud_router" {
  type        = bool
  description = "Whether to create a Cloud Router for Dataflow workers. Set to false if using an existing router."
  default     = true
}

variable "create_cloud_nat" {
  type        = bool
  description = "Whether to create a Cloud NAT for Dataflow workers outbound traffic. Set to false if using an existing NAT or if workers have external IPs."
  default     = true
}

variable "existing_router_name" {
  type        = string
  description = "Name of an existing Cloud Router to use for Cloud NAT. Required when create_cloud_nat = true and create_cloud_router = false."
  default     = ""
}

##############################################################################
# Dataflow Configuration
##############################################################################

variable "dataflow_job_name" {
  type        = string
  description = "Dataflow job name"
  default     = "datadog-export-job"
}

variable "dataflow_max_workers" {
  type        = number
  description = "The maximum number of Dataflow workers. Dataflow will autoscale up to this limit."
  default     = 3
  validation {
    condition     = var.dataflow_max_workers >= 1
    error_message = "max_workers must be at least 1."
  }
}

variable "dataflow_machine_type" {
  type        = string
  description = "The machine type for Dataflow worker VMs."
  default     = "n1-standard-4"
}

variable "dataflow_temp_bucket_name" {
  type        = string
  description = "GCS Bucket to write Dataflow temporary files. Must start and end with letter or number. Must be between 3 and 63 characters."
  default     = "temp-files-dataflow-bucket-"
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", var.dataflow_temp_bucket_name))
    error_message = "The bucket name must be between 3 and 63 characters, start and end with a letter or number, and contain only lowercase letters, numbers, and hyphens."
  }
}

##############################################################################
# Pub/Sub Configuration
##############################################################################

variable "topic_name" {
  type        = string
  description = "Name of the Pub/Sub Topic to receive logs from Google Cloud."
  default     = "datadog-export-topic"
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-_.~+%]{2,254}$", var.topic_name))
    error_message = "The topic name must start with a letter and be between 3 and 255 characters."
  }
}

variable "subscription_name" {
  type        = string
  description = "Name of the Pub/Sub subscription to receive logs from Google Cloud."
  default     = "datadog-export-sub"
  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-_.~+%]{2,254}$", var.subscription_name))
    error_message = "The subscription name must start with a letter and be between 3 and 255 characters."
  }
}

##############################################################################
# Datadog Configuration
##############################################################################

variable "datadog_api_key" {
  type        = string
  description = "Datadog API Key for integration."
  sensitive   = true
}

variable "datadog_site_url" {
  type        = string
  description = "Datadog Logs API URL, it will depends on the Datadog site region (https://docs.datadoghq.com/integrations/google_cloud_platform/#4-create-and-run-the-dataflow-job)."
  validation {
    condition     = can(regex("^https://", var.datadog_site_url))
    error_message = "The Datadog site URL must start with https://."
  }
}

##############################################################################
# Logging Configuration
##############################################################################

variable "log_sink_name" {
  type        = string
  description = "Name of the logging sink to route logs from GCP to Datadog."
  default     = "datadog-export-sink"
}

variable "log_sink_in_folder" {
  type        = bool
  description = "Set to true if the Log Sink should be created at the folder level."
  default     = false
}

variable "folder_id" {
  type        = string
  description = "Folder ID where the Log Sink should be created. Set to null if not in a folder."
  default     = ""
}

variable "inclusion_filter" {
  type        = string
  description = "Inclusion filter to be used by the Log sink for the logs to be forwarded to Datadog."
  default     = ""
}
