provider "google" {
  project = ""
  region  = ""
}

provider "google-beta" {
  project = ""
  region  = ""
}

module "datadog-integration" {
  source = "./gcp-datadog-module"

  # Project Configuration
  project_id  = ""
  name_prefix = "prefix" # Optional: Prefix for all resource names to avoid collisions
  labels      = {}       # Optional: Labels to apply to all resources
  # enabled_apis = []    # Optional: Override default APIs or set to [] if APIs are already enabled

  # Network Configuration
  vpc_name             = ""
  subnet_name          = ""
  subnet_region        = ""
  create_cloud_router  = true # Optional: Set to false if using existing router
  create_cloud_nat     = true # Optional: Set to false if using existing NAT or workers have external IPs
  existing_router_name = ""   # Optional: Required when create_cloud_nat = true and create_cloud_router = false

  # Dataflow Configuration
  dataflow_job_name         = ""
  dataflow_temp_bucket_name = ""
  dataflow_max_workers      = 3              # Optional: Maximum number of Dataflow workers
  dataflow_machine_type     = "n1-standard-4" # Optional: Machine type for Dataflow worker VMs

  # Pub/Sub Configuration
  topic_name        = "datadog-export-topic"
  subscription_name = "datadog-export-sub"

  # Datadog Configuration
  datadog_api_key  = ""
  datadog_site_url = ""

  # Logging Configuration
  log_sink_name      = "datadog-export-sink" # Optional: Override default sink name
  log_sink_in_folder = true
  folder_id          = ""
  inclusion_filter   = ""
}
