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

locals {
  # Extract the FQDN from the Datadog site URL, handling trailing slashes safely
  datadog_fqdn = trimsuffix(replace(var.datadog_site_url, "https://", ""), "/")
  # Prefix for all resources
  resource_prefix = var.name_prefix != "" ? "${var.name_prefix}-" : ""
  # Resolve the router name safely: prefer newly created, then existing, then empty
  router_name   = var.create_cloud_router ? google_compute_router.dataflow_router[0].name : var.existing_router_name
  router_region = var.create_cloud_router ? google_compute_router.dataflow_router[0].region : var.subnet_region
}
