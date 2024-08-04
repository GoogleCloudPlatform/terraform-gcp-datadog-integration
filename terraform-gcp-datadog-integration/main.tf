
# module "datadog-integration" {
#   source                    = "./gcp-datadog-module"
#   project_id                = ""
#   region                    = ""
#   dataflow_job_name         = ""
#   dataflow_temp_bucket_name = ""
#   topic_name                = "datadog-export-topic"
#   subscription_name         = "datadog-export-sub"
#   vpc_name                  = ""
#   subnet_name               = ""
#   datadog_api_key           = ""
#   datadog_site_url          = ""
#   log_sink_in_folder        = true
#   folder_id                 = ""
#   inclusion_filter          = ""
# }

# project log sink
module "datadog-integration" {
  source                    = "./gcp-datadog-module"
  project_id                = "diegonz-joonix-sandbox-3"
  region                    = "us-east1"
  dataflow_job_name         = "datadog-export-job"
  dataflow_temp_bucket_name = "dagg-joonix-bucket"
  topic_name                = "datadog-export-topic"
  subscription_name         = "datadog-export-sub"
  vpc_name                  = "dataflow-vpc"
  subnet_name               = "dataflow-subnet"
  datadog_api_key           = "3b0f373b2cbba59b42e0c34e5265e51e"
  datadog_site_url          = "https://http-intake.logs.us5.datadoghq.com"
  log_sink_in_folder        = true
  folder_id                 = "996464398988"
  inclusion_filter          = ""
}
