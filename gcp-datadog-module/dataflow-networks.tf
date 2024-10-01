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

# Fetch VPC/Subnet network details
data "google_compute_network" "vpc" {
  name = var.vpc_name
}

data "google_compute_subnetwork" "dataflow_subnetwork" {
  name   = var.subnet_name
  region = var.subnet_region
}

###################################################################################################
### EGRESS FIREWALL POLICY/RULE TO ALLOW DATAFLOW WORKER VM'S TO REACH THE DATADOG LOGS API URL ###
###################################################################################################

# Create the Firewall policy
resource "google_compute_region_network_firewall_policy" "allow_datadog_policy" {
  name        = "allow-workers-to-datadog-policy"
  description = "Firewall policy to allow traffic from Dataflow Workers to Datadog"
  project     = var.project_id
  region      = var.subnet_region
}

# Create the Firewall rule for the policy
resource "google_compute_region_network_firewall_policy_rule" "allow_datadog_rule" {
  action          = "allow"
  description     = "Firewall rule to allow traffic from Dataflow workers to Datadog FQDN"
  direction       = "EGRESS"
  firewall_policy = google_compute_region_network_firewall_policy.allow_datadog_policy.name
  priority        = 365000000
  region          = var.subnet_region
  rule_name       = "allow-datadog-fqdm"

  match {
    src_ip_ranges = [data.google_compute_subnetwork.dataflow_subnetwork.ip_cidr_range]
    dest_fqdns    = [substr(var.datadog_site_url, 8, length(var.datadog_site_url) - 8)]

    layer4_configs {
      ip_protocol = "tcp"
      ports       = ["443"]
    }
  }
}

# Attach the Firewall policy to a VPC
resource "google_compute_region_network_firewall_policy_association" "vpc_association" {
  name              = "vpc_association"
  attachment_target = data.google_compute_network.vpc.id
  firewall_policy   = google_compute_region_network_firewall_policy.allow_datadog_policy.name
  project           = var.project_id
  region            = var.subnet_region
}

##############################################################################
############## INGRESS COMMUNICATION BETWEEN DATAFLOW WORKERS ################
##############################################################################

resource "google_compute_firewall" "ingress_rule_dataflow" {
  name     = "ingress-rule-dataflow-workers"
  project  = var.project_id
  network  = data.google_compute_network.vpc.id
  priority = 200

  # Allow inbound traffic on specific ports (12345-12346)
  allow {
    ports    = ["12345-12346"]
    protocol = "tcp"
  }

  direction = "INGRESS"

  # Apply the rule to instances with "dataflow" tag
  source_tags = ["dataflow"]
  target_tags = ["dataflow"]
}

##############################################################################
############ EGRESS COMMUNICATION BETWEEN DATAFLOW WORKERS ###################
##############################################################################

resource "google_compute_firewall" "egress_dataflow_workers" {
  name     = "egress-rule-dataflow-workers"
  project  = var.project_id
  network  = data.google_compute_network.vpc.id
  priority = 210

  # Allow outbound traffic on port 443 (HTTPS)
  allow {
    ports    = ["12345-12346"]
    protocol = "tcp"
  }

  # Define destination IP ranges for Datadog Logs API URL
  destination_ranges = [data.google_compute_subnetwork.dataflow_subnetwork.ip_cidr_range]
  direction          = "EGRESS"

  # Apply the rule to instances with "dataflow" tag
  target_tags = ["dataflow"]
}
##############################################################################
############## CLOUD ROUTER AND CLOUD NAT FOR OUTBOUND TRAFFIC ###############
##############################################################################

resource "google_compute_router" "dataflow_router" {
  name    = "dataflow-router"
  network = data.google_compute_network.vpc.id
  project = var.project_id
  region  = var.subnet_region
}

resource "google_compute_router_nat" "nat" {
  name                               = "dataflow-machines-nat"
  router                             = google_compute_router.dataflow_router.name
  region                             = google_compute_router.dataflow_router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
