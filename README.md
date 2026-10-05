# terraform-noop-machinepool

The no-op CAPTF `machinepool` module: the Terraform/OpenTofu root module behind
`TerraformMachinePool` that implements the `v1alpha1` machinepool role and provisions
nothing. Every resource is a `terraform_data` holding its inputs, so plans,
state and outputs are real and no cloud account is needed. Use it to try
CAPTF without a cloud account, to exercise a management cluster, as the
provider's e2e target, or as a starting point for a real module.

The module image `ghcr.io/captf-io/noop-machinepool` is built and published from
[noop-modules](https://github.com/captf-io/noop-modules); this repository
holds the code and its checks.

## What it returns

`provider_id` `noop-group:///<namespace>/<name>`; one `noop:///…/<i>` instance per replica. It reports `health` as running and healthy.

No machine joins a cluster: the endpoint never resolves and no node
registers, so a Machine reaches `Provisioned` but never gets a `nodeRef`.
The module exercises the provider, not Kubernetes.

## Using it

Set the module image on the `TerraformMachinePool`'s `spec.source.image`, e.g.
`ghcr.io/captf-io/noop-machinepool:opentofu`. See the
[CAPTF documentation](https://captf.io/docs/) for installing the provider
and its clusterctl templates.

## Development

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
