# Log Collection Integration - Google Cloud Platform to Datadog

This Terraform module automates the integration between **Google Cloud Platform and Datadog for Log collection**, making the process faster and more efficient.  It builds upon the foundational overview provided in the official [Datadog guide](https://docs.datadoghq.com/integrations/google_cloud_platform/#log-collection). The module simplifies integration, accelerates implementation, and addresses essential security considerations for a successful observability strategy.

While this module provides security foundational principles, it's essential to note that in highly sensitive or production Google Cloud environments, additional layers of security and design principles should be thoughtfully analyzed and applied to uphold the highest standards of data protection and security principles (e.g. Utilize a bucket for TF state backup and encryption, egress traffic flow analysis, apply the module across various folders, disruption analysis, etc).

These deployment scripts are provided 'as is', without warranty. See [Copyright & License](https://github.com/googlecloudplatform/terraform-gcp-datadog-integration/blob/main/LICENSE).

## Solution diagram

![Image alt text](gcp-to-datadog-diagram.png)

## Resources created

* `google_logging_folder_sink` OR `google_logging_project_sink`: Logs forwarder from Google Cloud Logging to Pub/Sub.
* `google_pubsub_topic` & `google_pubsub_subscription`: Service that handles the Logs sent by Cloud Logging and delivers it to Dataflow.
* `google_secret_manager_secret` & `google_secret_manager_secret_version`: Used to store the Datadog API Key in a secure way.
* `google_dataflow_job`: Create the Dataflow worker machines (Compute Engine) and generate a Dataflow job to pull logs from Pub/Sub subscription and export it to Datadog.
* `google_storage_bucket`: Used to store Dataflow temporary files.
* `google_compute_region_network_firewall_policy_rule`: Used to allow traffic from Dataflow workers private IP's to Datadog.
* `google_compute_firewall`: Used to allow internal traffic between Dataflow worker machines.
* `google_compute_router`: Used to serve as the control plane for network packets and to be attached to Cloud NAT.
* `google_compute_router_nat`: Required for outbound connections to the internet for the Dataflow private IP's workers - <span style="color:red"> **IMPORTANT**</span>: Take into account that if you already have virtual machines (VMs) in the same subnet as the one that Cloud NAT will use, those VMs will have outbound connectivity too.

**Note**: It's recommended to utilize a distinct project specifically for the deployment of all resources related to this integration.

## Prerequisites

* A Virtual Private Cloud (VPC) - Required in the '**`vpc_name`**' input variable.
* A network subnet attached to the VPC with [Private Google Access](https://cloud.google.com/vpc/docs/private-google-access) enabled (Resources will be created in the subnet's region) -  Required in the '**`subnet_name`**' input variable.
* Datadog API Key - Required in the '**`datadog_api_key`**' input variable
* Your Datadog Logs API URL (You can find it [here](https://docs.datadoghq.com/integrations/google_cloud_platform/#4-create-and-run-the-dataflow-job), **ensure** the site selector on the right part of the page is the correct for your Datadog site) - used in the  '**`datadog_site_url`**' input variable
* A pre-selected inclusion filter for the logs you want to be sent to Datadog -  <span style="color:red"> **IMPORTANT**</span>: To make the filter works using Terraform you must use *unquoted* filters. 

  Instead of **this**: 
  ```python
  resource.type="gce_instance" AND protoPayload.methodName="v1.compute.instances.stop"
  ```
  Use **this**:
  ```python
  resource.type=gce_instance AND protoPayload.methodName=v1.compute.instances.stop
  ```

  If your desired filter is too complicated, start with a basic one or an empty one (*inclusion_filter = ""*). After running 'Terraform apply', you can easily adjust the filter in the sink configs manually.

## Usage

Fill the `main.tf` file with your input variables and from the root folder of this repo (where the `main.tf` file exists) run the **terraform init, plan, and apply** commands.<br><br>

### Use a Log sink at the folder level

```hcl
module "datadog-integration" {
  source                    = "./gcp-datadog-module"
  project_id                = "my-gcp-project-id"
  dataflow_job_name         = "datadog-export-job"
  dataflow_temp_bucket_name = "my-temp-bucket"
  topic_name                = "datadog-export-topic"
  subscription_name         = "datadog-export-sub"
  vpc_name                  = "vpc-name"
  subnet_name               = "subnet-name"
  subnet_region             = "us-east1"
  datadog_api_key           = "ab1c23d4ef56789a0bc1d23ef45ab6789"
  datadog_site_url          = "https://http-intake.logs.us5.datadoghq.com"
  log_sink_in_folder        = true
  folder_id                 = "123456789012"
  inclusion_filter          = "resource.type=gce_instance AND protoPayload.methodName=v1.compute.instances.stop"
}
```

### Use a Log sink at the project level

```hcl
module "datadog-integration" {
  source                    = "./gcp-datadog-module"
  project_id                = "my-gcp-project-id"
  dataflow_job_name         = "datadog-export-job"
  dataflow_temp_bucket_name = "my-temp-bucket"
  topic_name                = "datadog-export-topic"
  subscription_name         = "datadog-export-sub"
  vpc_name                  = "vpc-name"
  subnet_name               = "subnet-name"
  subnet_region             = "us-east1"
  datadog_api_key           = "ab1c23d4ef56789a0bc1d23ef45ab6789"
  datadog_site_url          = "https://http-intake.logs.us5.datadoghq.com"
  inclusion_filter          = ""
}
```

## Variables

| Variable Name | Type | Description | Default Value |Example |
|-|-|-|-|-|
| project_id         | string | The ID of the Google Cloud  project.                                       | |"my-gcp-project"|
| subnet_region      | string | Region of the existing subnet, **all the resources will be created in this region.** | | "us-central1" |
| dataflow_job_name  | string  | Dataflow job name | "datadog-export-job" | "export-job"   |
| dataflow_temp_bucket_name| string  | GCS Bucket to write Dataflow temporary files. Must start and end with a letter or number. Must be between 3 and 63 characters. | "temp-files-dataflow-bucket-" | "my-temp-bucket" |
| topic_name         | string | Name of the Pub/Sub Topic to receive logs from Google Cloud.        | datadog-export-topic | "my-datadog-topic" |
| subscription_name  | string | Name of the Pub/Sub subscription to receive logs from Google Cloud. | datadog-export-sub   | "my-datadog-subscription" |
| vpc_name           | string | Name of the VPC used for Dataflow Virtual Machines.                 | | "my-dataflow-vpc" | 
| subnet_name        | string | Name of the subnets used for Dataflow Virtual Machines.             | | "my-subnet-name"|
| datadog_api_key    | string | Datadog API Key for integration.                                    | | "ab1c23d4ef56789a0bc1d23ef45ab6789" |
| datadog_site_url   | string | Datadog Logs API URL, it depends on the Datadog site region (see [Datadog documentation](https://docs.datadoghq.com/integrations/google_cloud_platform/#4-create-and-run-the-dataflow-job)). |  | "https://http-intake.logs.datadoghq.com" |
| log_sink_in_folder | boolean| Set to true if the Log Sink should be created at the folder level.                   | false | true |
| folder_id          | string | Folder ID where the Log Sink should be created. Set to null if not in a folder.      | ""  | "123456789012" | 
| inclusion_filter   | string | Inclusion filter to be used by the Log sink for the logs to be forwarded to Datadog. | ""    | "resource.type=gce_instance AND resource.labels.project_id=my-project-id"

## Outputs

| Output Name                  | Description                                          | Value                                                        |
| ---------------------------- | ---------------------------------------------------- | ------------------------------------------------------------ |
| dataflow_job_name            | The name of the created Dataflow job.                | `google_dataflow_job.pubsub_stream_to_datadog.name`         |
| temp_files_bucket_name       | The name of the created temporary files bucket.      | `google_storage_bucket.temp_files_bucket.name`              |
| datadog_topic_name           | The name of the created Pub/Sub topic.               | `google_pubsub_topic.datadog_topic.name`                    |
| datadog_subscription_name    | The name of the created Pub/Sub subscription.        | `google_pubsub_subscription.datadog_topic_sub.name`         |

## Additional Considerations

* Customization: The module is flexible and allows you to customize various aspects of the integration. Your specific Google Cloud organization might have unique requirements, so you may need to adjust the code to suit your particular situation (e.g., deploying the log sink across multiple folders or at the organization level, use a different solution for API key store, etc.)

## Authors

* **Diego González** - [diegonz2](https://github.com/diegonz2)

## Troubleshooting

* If the Dataflow job fails with a *"Workflow failed. Causes: There was a problem refreshing your credentials"* error, re-run "terraform apply"
