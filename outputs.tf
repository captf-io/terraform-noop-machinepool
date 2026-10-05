# Copyright 2026 The CAPTF Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Contract outputs of the machinepool role, v1alpha1.

locals {
  # Synthetic per-replica ids; unsorted here, sorted at each output that
  # needs the canonical order (provider_id_list must be sort()/distinct()
  # wrapped directly in its own output expression: output/provider-id-list-shape).
  raw_ids = [for i in range(var.replicas) : "noop:///${var.captf_object.namespace}/${var.captf_object.name}/${i}"]
}

# Stable per TerraformMachinePool. With no native scaling group behind it,
# this is a synthetic group id (machinepool.md "provider_id ... may stay
# null for group-less implementations"; this module chooses to set one).
output "provider_id" {
  value = "noop-group:///${var.captf_object.namespace}/${var.captf_object.name}"
}

output "provider_id_list" {
  value = sort(local.raw_ids)
}

output "replicas" {
  value = var.replicas
}

output "instances" {
  value = [for id in sort(local.raw_ids) : { provider_id = id, state = "running" }]
}

output "health" {
  value = { state = "running", healthy = true, message = null, reasons = [] }
}
