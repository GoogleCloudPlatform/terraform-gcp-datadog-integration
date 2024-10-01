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

##################################################################
## CREATE A SECRET IN GOOGLE SECRET MANAGER FOR DATADOG API KEY ##
##################################################################

resource "google_secret_manager_secret" "datadog_secret" {
  secret_id = "datadog-api"

  replication {
    user_managed {
      replicas {
        location = var.subnet_region
      }
    }
  }

  # Ensure this resource depends on API services being enabled
  depends_on = [google_project_service.enable_apis]
}

# Create a secret version with the Datadog API key
resource "google_secret_manager_secret_version" "secret_version" {
  secret      = google_secret_manager_secret.datadog_secret.id
  secret_data = var.datadog_api_key
}
