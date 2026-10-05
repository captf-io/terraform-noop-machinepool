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
  type = string
}

variable "captf_cluster" {
  type = object({
    name      = string
    namespace = string
  })
}

variable "captf_object" {
  type = object({
    kind      = string
    name      = string
    namespace = string
  })
}

# The cluster module's exports. The controller always sets it; the default
# follows the contract skeleton (machinepool.md).
variable "captf_cluster_outputs" {
  type    = any
  default = null
}

variable "captf_tags" {
  type = map(string)
}

variable "machinepool_name" {
  type = string
}

# The group's desired capacity.
variable "replicas" {
  type = number
}

# Base64 of the bootstrap Secret's value.
variable "bootstrap_data" {
  type      = string
  sensitive = true
}

variable "bootstrap_format" {
  type = string
}

variable "failure_domains" {
  type = list(string)
}

variable "cluster_failure_domains" {
  type = list(string)
}

variable "kubernetes_version" {
  type    = string
  default = null
}

variable "node_labels" {
  type = map(string)
}

variable "autoscaling" {
  type = object({
    enabled = bool
    min     = number
    max     = number
  })
}
