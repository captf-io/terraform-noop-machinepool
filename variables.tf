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

# Contract inputs of the machinepool role, v1alpha1 (https://docs.captf.io/module-author/contract/v1alpha1/common.html
# and machinepool.html).

variable "captf_contract" {
  description = "Contract version the controller generated the root for; always v1alpha1."
  type        = string
}

variable "captf_cluster" {
  description = "The owning CAPI Cluster: name and namespace."
  type = object({
    name      = string
    namespace = string
  })
}

variable "captf_object" {
  description = "The TerraformMachinePool being reconciled: kind, name and namespace."
  type = object({
    kind      = string
    name      = string
    namespace = string
  })
}

# The cluster module's exports. The controller always sets it; the default
# follows the contract skeleton (machinepool.md).
variable "captf_cluster_outputs" {
  description = "The cluster role's exports (backend_id from terraform-noop-cluster). Null by default, following the contract skeleton."
  type        = any
  default     = null
}

variable "captf_tags" {
  description = "Tags the controller always sets (captf.io/cluster, captf.io/namespace, captf.io/kind, captf.io/name, captf.io/managed-by, captf.io/template); held in terraform_data like every other input."
  type        = map(string)
}

variable "machinepool_name" {
  description = "The owning CAPI MachinePool's name. Held, otherwise unused."
  type        = string
}

# The group's desired capacity.
variable "replicas" {
  description = "The pool's desired size: the number of stand-in instances."
  type        = number
}

# Base64 of the bootstrap Secret's value.
variable "bootstrap_data" {
  description = "Base64 of the bootstrap Secret's value. Held, never parsed or delivered."
  type        = string
  sensitive   = true
}

variable "bootstrap_format" {
  description = "The bootstrap payload's format: cloud-config or ignition."
  type        = string
}

variable "failure_domains" {
  description = "MachinePool.spec.failureDomains. Held, otherwise unused."
  type        = list(string)
}

variable "cluster_failure_domains" {
  description = "The cluster's failure-domain names. Held, otherwise unused."
  type        = list(string)
}

variable "kubernetes_version" {
  description = "MachinePool.spec.template.spec.version. Held, otherwise unused."
  type        = string
  default     = null
}

variable "node_labels" {
  description = "MachinePool.spec.template.metadata.labels. Held, otherwise unused."
  type        = map(string)
}

variable "autoscaling" {
  description = "Parsed from the MachinePool's autoscaler min and max size annotations. Held, otherwise unused."
  type = object({
    enabled = bool
    min     = number
    max     = number
  })
}
