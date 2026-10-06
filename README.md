<h1 align="center">
  <a href="https://captf.io/"><img
    src="https://captf.io/assets/readme/mark.svg"
    width="72" height="72" alt="CAPTF"></a>
  <br>
  terraform-noop-machinepool
</h1>

<p align="center">A no-op CAPTF machine pool module for trying and testing</p>

<p align="center">
  <a href="https://github.com/captf-io/terraform-noop-machinepool/actions/workflows/ci.yml"><img
    src="https://img.shields.io/github/actions/workflow/status/captf-io/terraform-noop-machinepool/ci.yml?branch=main&amp;label=build&amp;labelColor=161B3A&amp;style=flat-square"
    alt="build"></a>
  <a href="https://captf.io/docs/module-author/contract/index.html"><img
    src="https://img.shields.io/static/v1?label=contract&amp;message=v1alpha1&amp;color=A974FF&amp;labelColor=161B3A&amp;style=flat-square"
    alt="contract v1alpha1"></a>
  <a href="https://captf.io/docs/"><img
    src="https://img.shields.io/static/v1?label=docs&amp;message=captf.io&amp;color=5B8CFF&amp;labelColor=161B3A&amp;style=flat-square"
    alt="docs captf.io"></a>
  <a href="https://github.com/captf-io/terraform-noop-machinepool/blob/main/LICENSE.md"><img
    src="https://img.shields.io/static/v1?label=license&amp;message=Apache-2.0&amp;color=FFD84D&amp;labelColor=161B3A&amp;style=flat-square"
    alt="license Apache-2.0"></a>
</p>

> [!NOTE]
> **Pre-release.** CAPTF is `v1alpha1`: its API and its
> [module contract](https://captf.io/docs/module-author/contract/index.html)
> may still change between releases.

The no-op CAPTF `machinepool` module: the Terraform/OpenTofu root module behind
`TerraformMachinePool` that implements the `v1alpha1` machinepool role and provisions
nothing. Every resource is a `terraform_data` holding its inputs, so plans,
state and outputs are real and no cloud account is needed. Use it to try
CAPTF without a cloud account, to exercise a management cluster, as the
provider's e2e target, or as a starting point for a real module.

The module image `ghcr.io/captf-io/module-images/noop-machinepool` is built and published by
[module-images](https://github.com/captf-io/module-images) from this repository's releases. This
repository holds the code and its checks.

## What it returns

`provider_id` `noop-group:///<namespace>/<name>`; one `noop:///…/<i>` instance per replica. It reports `health` as running and healthy.

No machine joins a cluster: the endpoint never resolves and no node
registers, so a Machine reaches `Provisioned` but never gets a `nodeRef`.
The module exercises the provider, not Kubernetes.

## Using it

CAPTF runs this module from the module image
`ghcr.io/captf-io/module-images/noop-machinepool`: set the image on a `TerraformMachinePool`'s
`spec.source.image`, and the controller renders every input. The module is also
published to the Terraform Registry as `captf-io/machinepool/noop` and can be
called directly:

```hcl
module "machinepool" {
  source  = "captf-io/machinepool/noop"
  version = "~> 0.1"

  # The contract inputs the controller would render (captf_contract,
  # captf_cluster, captf_object, captf_tags, ...; see Inputs), and any
  # user variables.
}
```

It needs no providers and no credentials, which makes it a convenient
fixture for testing a configuration that drives CAPTF modules.

## Developing

The host needs make and podman (or docker with `ENGINE=docker`); the
runtimes run in containers pinned by digest. `make verify` is the gate CI
runs.

| Target | What it does |
| --- | --- |
| `fmt` / `fmt-check` | `terraform fmt` and `tofu fmt`, in place or as a check |
| `validate` | `init` and `validate` on Terraform and OpenTofu and on their floors (1.5.7, 1.6.3) |
| `test` | apply, output and destroy `test/root`, which calls the module with every contract input, on each runtime and floor |
| `check-headers` / `fix-headers` | the Apache-2.0 license header on every source file |
| `verify` | all of the above |
| `clean` | remove `build/` |

`RUNTIMES=opentofu` limits a target to one runtime.

<br>
<p align="center">
  <img
    src="https://captf.io/assets/readme/divider.svg"
    width="100%" height="4" alt="">
</p>
<p align="center">
  <a href="https://captf.io/"><img
    src="https://captf.io/assets/readme/mark.svg"
    width="40" height="40" alt="CAPTF"></a>
  <br>
  <a href="https://captf.io/docs/"
    ><b>Documentation</b></a> ·
  <a href="https://captf.io/docs/getting-started/quick-start.html"
    ><b>Quick start</b></a> ·
  <a href="https://github.com/captf-io/.github/blob/main/CONTRIBUTING.md"
    ><b>Contributing</b></a> ·
  <a href="https://github.com/captf-io/.github/blob/main/SECURITY.md"
    ><b>Security</b></a>
  <br>
  <sub>Built for
    <a href="https://cluster-api.sigs.k8s.io/">Cluster API</a>.
    <a href="https://github.com/captf-io/terraform-noop-machinepool/blob/main/LICENSE.md"
    >Apache 2.0</a>.</sub>
</p>
