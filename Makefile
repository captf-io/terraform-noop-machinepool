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

# Every check for the no-op machinepool module, which is the root of this
# repository. `make help` lists the targets.
#
# The host needs make and podman (or docker with ENGINE=docker). The runtimes
# run in containers pinned by digest, as the host user, with the repository
# mounted at /work; nothing in the repository is left owned by root.

SHELL := bash
.SHELLFLAGS := -euo pipefail -c
.NOTPARALLEL:

# ---- Variables: override on the command line, e.g. `make test RUNTIMES=opentofu`.

ROLE := machinepool
ENGINE ?= podman
RUNTIMES ?= terraform opentofu

# Runtime images, pinned by digest: the CAPTF base images the module images
# build FROM. The floors are the oldest runtimes the module supports
# (versions.tf: terraform_data needs 1.4, plantimestamp() 1.5).
TF_IMAGE_terraform := ghcr.io/captf-io/terraform-base:1.16.5@sha256:974c18d5fbbbf1701bdc060b8c3838934cb4780ceb1683207ae43e48573f94e2
TF_IMAGE_opentofu := ghcr.io/captf-io/opentofu-base:1.12.7@sha256:eb9c589b3036f4e0914b56969c84b11ce50ea1527f49bddfb8896531547ba798
TF_FLOOR_terraform := docker.io/hashicorp/terraform:1.5.7@sha256:9fc0d70fb0f858b0af1fadfcf8b7510b1b61e8b35e7a4bb9ff39f7f6568c321d
TF_FLOOR_opentofu := ghcr.io/opentofu/opentofu:1.6.3@sha256:bcfdb7fcd385eb62c3389f7b06f5813de55d09d709498fbb5421dcc6dd4c3d06
LICENSE_EYE_IMAGE := docker.io/apache/skywalking-eyes:0.9.0@sha256:cd89ccbbcba2e87d3fb0e34b156b1da208d6c5ac1ada4e2d335e920022c765b8

ifeq ($(ENGINE),docker)
USER_FLAGS := --user $(shell id -u):$(shell id -g)
else
USER_FLAGS := --userns=keep-id --user $(shell id -u):$(shell id -g)
endif
# A container with the repository at /work, as the host user.
CONTAINER = $(ENGINE) run --rm $(USER_FLAGS) --security-opt label=disable \
	-e HOME=/tmp -v "$(CURDIR):/work" -w /work

# hack/tf-run.sh reads the pins for `default` from these.
export ENGINE TF_IMAGE_terraform TF_IMAGE_opentofu

.PHONY: help fmt fmt-check validate test check-headers fix-headers verify clean

help: ## Show targets.
	@grep -E '^[a-zA-Z0-9_-]+:.*## ' $(MAKEFILE_LIST) | awk -F ':.*## ' '{printf "%-14s %s\n", $$1, $$2}'
	@echo
	@echo "ROLE=$(ROLE) RUNTIMES=$(RUNTIMES) ENGINE=$(ENGINE)"

fmt: ## Format the module with terraform fmt and tofu fmt, in place.
	@for rt in $(RUNTIMES); do hack/tf-run.sh fmt "$$rt" default; done

fmt-check: ## Fail on any file terraform fmt or tofu fmt would change.
	@for rt in $(RUNTIMES); do hack/tf-run.sh fmt-check "$$rt" default; done

validate: ## init + validate on both runtimes and on their floors (Terraform 1.5.7, OpenTofu 1.6.3).
	@for rt in $(RUNTIMES); do \
		hack/tf-run.sh validate "$$rt" default; \
		case "$$rt" in \
			terraform) hack/tf-run.sh validate "$$rt" "$(TF_FLOOR_terraform)" ;; \
			opentofu) hack/tf-run.sh validate "$$rt" "$(TF_FLOOR_opentofu)" ;; \
		esac; \
	done

test: ## Apply and destroy test/root (every contract input) on both runtimes and their floors.
	@for rt in $(RUNTIMES); do \
		hack/tf-run.sh test "$$rt" default; \
		case "$$rt" in \
			terraform) hack/tf-run.sh test "$$rt" "$(TF_FLOOR_terraform)" ;; \
			opentofu) hack/tf-run.sh test "$$rt" "$(TF_FLOOR_opentofu)" ;; \
		esac; \
	done

check-headers: ## Fail on any source file without the Apache-2.0 license header (.licenserc.yaml).
	@$(CONTAINER) "$(LICENSE_EYE_IMAGE)" header check

fix-headers: ## Add the Apache-2.0 license header to every source file missing it.
	@$(CONTAINER) "$(LICENSE_EYE_IMAGE)" header fix

verify: check-headers fmt-check validate test ## Every check above; the CI gate.
	@echo "verify: ok"

clean: ## Remove build/ (the staged module and test root).
	@d='$(CURDIR)/build'; \
	if [ -d "$$d" ] && [ ! -L "$$d" ] && [ -f '$(CURDIR)/Makefile' ] && [ "$$d" = "$$(cd '$(CURDIR)' && pwd -P)/build" ]; then \
		echo "clean: removing $$d"; rm -rf -- "$$d"; \
	else \
		echo "clean: no build/ to remove"; \
	fi

print-%: ## Print a variable, e.g. `make print-ROLE`.
	@printf '%s\n' '$($*)'
