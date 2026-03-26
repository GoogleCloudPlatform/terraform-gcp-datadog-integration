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

# Enable GCP APIs
resource "google_project_service" "enable_apis" {
  project = var.project_id

  for_each = toset(var.enabled_apis)

  service                    = each.key
  disable_on_destroy         = var.disable_on_destroy
  disable_dependent_services = var.disable_dependent_services

  # Prevents Terraform timeout if API enablement is slow
  timeouts {
    create = "30m"
    update = "40m"
  }

}

# Wait for APIs to be fully enabled and Dataflow 'producer' SA to be created.
# Only wait if APIs are actually being enabled to avoid unnecessary delays.
resource "time_sleep" "wait_for_apis" {
  count           = length(var.enabled_apis) > 0 ? 1 : 0
  create_duration = "60s"

  depends_on = [google_project_service.enable_apis]
}
