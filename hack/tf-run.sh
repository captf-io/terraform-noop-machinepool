#!/usr/bin/env bash
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

# Run one Terraform or OpenTofu action on the module (the repository root)
# in a container pinned by digest. The Makefile calls this; run it by hand to
# reproduce one cell of `make validate` or `make test`.
#
# Usage: hack/tf-run.sh <action> <terraform|opentofu> <image|default>
#
# Actions:
#   fmt        fmt in place
#   fmt-check  fmt -check -diff
#   validate   init, then validate the module
#   test       init, validate, apply, output and destroy test/root, the root
#              module that calls this one with every contract input, the way
#              the CAPTF runner does (local state, thrown away with the stage)
#
# <image> is a full image reference, or `default` for the pinned runtime
# image in $TF_IMAGE_<runtime> (the Makefile exports both). Everything but
# fmt runs on a copy in build/stage/<runtime>-<image>/: the module in
# module/ and test/root in work/root/, so the root's `../../module` source
# resolves as it does inside a module image. The module needs no providers.
#
# Env: ENGINE (podman|docker, default podman),
#      TF_IMAGE_terraform, TF_IMAGE_opentofu (the images for `default`).
set -euo pipefail

usage="usage: tf-run.sh <fmt|fmt-check|validate|test> <terraform|opentofu> <image|default>"
action=${1:?$usage}
runtime=${2:?$usage}
image=${3:?$usage}

engine=${ENGINE:-podman}
root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"

case $runtime in
  terraform) bin=terraform ;;
  opentofu) bin=tofu ;;
  *) echo "$usage" >&2; exit 2 ;;
esac
[[ -f versions.tf ]] || { echo "tf-run.sh: versions.tf not found at the repository root" >&2; exit 2; }

if [[ $image == default ]]; then
  var=TF_IMAGE_$runtime
  image=${!var:-}
  [[ -n $image ]] || { echo "tf-run.sh: $var is not set; run through make, or set it to an image" >&2; exit 2; }
fi

case $engine in
  docker) user_flags=(--user "$(id -u):$(id -g)") ;;
  # The images set USER 65532, which wins over keep-id's default, so the
  # user is explicit; keep-id maps it to the host user for file ownership.
  *) user_flags=(--userns=keep-id --user "$(id -u):$(id -g)") ;;
esac

# container_run <workdir-under-/work> <script>: the script runs under sh with
# the repository mounted at /work, as the host user.
container_run() {
  "$engine" run --rm "${user_flags[@]}" --security-opt label=disable \
    -e HOME=/tmp -e CHECKPOINT_DISABLE=1 -e TF_IN_AUTOMATION=1 -e TF_INPUT=0 \
    -v "$root:/work" -w "/work/$1" --entrypoint /bin/sh \
    "$image" -euc "$2"
}

echo "--- $action: module on $runtime (${image%%@*})"
case $action in
  fmt)
    container_run . "$bin fmt -no-color ."
    exit 0
    ;;
  fmt-check)
    container_run . "$bin fmt -check -diff -no-color ."
    exit 0
    ;;
  validate | test) ;;
  *) echo "$usage" >&2; exit 2 ;;
esac

# Stage the module and the test root. The label keeps stages of different
# images apart.
label=$(printf '%s' "${image%%@*}" | tr -c 'A-Za-z0-9._\n-' '_')
stage="build/stage/$runtime-$label"
case $stage in
  build/stage/?*) ;;
  *) echo "tf-run.sh: refusing to stage into '$stage'" >&2; exit 1 ;;
esac
if [[ -e $stage ]]; then
  [[ -d $stage && ! -L $stage ]] || { echo "tf-run.sh: $stage is not a directory" >&2; exit 1; }
  rm -rf -- "$stage"
fi
mkdir -p "$stage/module" "$stage/work/root"
cp -- ./*.tf "$stage/module/"
cp -- test/root/main.tf.json "$stage/work/root/"

init="$bin init -backend=false -input=false -no-color"
case $action in
  validate)
    container_run "$stage/module" "$init && $bin validate -no-color"
    ;;
  test)
    container_run "$stage/work/root" "$bin init -input=false -no-color \
      && $bin validate -no-color \
      && $bin apply -auto-approve -no-color \
      && $bin output -json -no-color \
      && $bin destroy -auto-approve -no-color"
    ;;
esac
