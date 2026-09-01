# Echo service on Kind with Pulumi

A Go echo web service, packaged in a distroless container, and deployed to a
local Kubernetes cluster created with [Kind](https://kind.sigs.k8s.io/). State
is stored in a local Pulumi file backend, so no cloud account is required.

## What it does

Every request returns a JSON echo of the request:

```bash
curl "http://localhost:30080/anything?a=1" -d 'payload'
```

Response:

```json
{
  "headers": { ... },
  "params": { "a": ["1"] },
  "body": "payload",
  "path": "/anything"
}
```

## Requirements

- Docker daemon running
- bash, curl, jq

All other tools (Go 1.25, Kind, kubectl, Pulumi CLI) are installed into
`.tools/` by `scripts/bootstrap.sh` — no sudo required.

## Quick start

```bash
cd Pulumi

export PULUMI_BACKEND_URL="file://$PWD/.pulumi"
export PULUMI_CONFIG_PASSPHRASE=""

scripts/bootstrap.sh --cluster
scripts/ci.sh
scripts/deploy.sh dev

curl "http://localhost:30080/hello?a=1" -d 'payload'
```

## Project layout

```
app/              Go echo service, unit tests, Dockerfile
infra/            Pulumi Go program (Deployment + NodePort Service)
kind-config.yaml  Kind cluster spec with registry mirror and host port 30080
scripts/          bootstrap.sh, ci.sh, deploy.sh, status.sh, start.sh, stop.sh, teardown.sh
Pulumi.yaml       Pulumi project config
Pulumi.dev.yaml   Stack config (image, replicas, nodePort)
.github/workflows/ci.yml
SETUP.md          How to spin up the environment from scratch
```

## Scripts

| Script                             | Purpose                                                                                                               |
| ---------------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| `scripts/bootstrap.sh --cluster` | Install tools into `.tools/`, create local registry and Kind cluster `pulumi-dev-cp`                               |
| `scripts/ci.sh`                  | Run tests, build the Docker image, push to registry                                                                  |
| `scripts/deploy.sh dev`          | Preview and deploy the Pulumi stack                                                                                  |
| `scripts/status.sh`              | Show cluster, deployment, pods, service and endpoints                                                                |
| `scripts/start.sh`              | Start a stopped cluster                                                                                               |
| `scripts/stop.sh`               | Stop the cluster (pauses it; reversible)                                                                              |
| `scripts/teardown.sh`           | Destroy stack, delete cluster and remove registry                                                                     |

All scripts self-bootstrap PATH to `.tools/`, so they work from a clean shell.

## Managing the cluster

```bash
scripts/status.sh
scripts/stop.sh
scripts/start.sh
scripts/teardown.sh
```

## Configuration

`Pulumi.yaml` declares typed defaults. Stack configs override:

```yaml
# Pulumi.dev.yaml — dev stack
echo:replicas: "2"
echo:image: localhost:5001/echo-service:ci
echo:nodePort: "30080"

# Pulumi.prod.yaml — prod stack
echo:replicas: "3"
echo:image: localhost:5001/echo-service:main
echo:nodePort: "30080"
```

## Branches and environments

| Branch | Stack | Image tag | Replicas |
|--------|-------|-----------|----------|
| `dev`  | `dev`  | `echo-service:dev`  | 2 |
| `main` | `prod` | `echo-service:main` | 3 |

Both stacks deploy to the same local cluster, so deploy one at a time (or
recreate the cluster per stack). CI builds and publishes `echo-service:<branch>`
to GHCR on every push to either branch.

Changing `nodePort` also requires the same port in `kind-config.yaml`
`extraPortMappings`, and a fresh cluster because port mappings are fixed at
creation time.

## Container

The image is built with `CGO_ENABLED=0` and runs as `nonroot` on a distroless
base image.

## CI

`.github/workflows/ci.yml` runs tests and builds the image on every push and
pull request. On pushes to `main` or `dev` it also publishes to GHCR, tagged
with the branch name.

## Tear down

```bash
scripts/teardown.sh   # destroy stack, delete cluster, remove registry
```

Or manually:

```bash
(cd infra && pulumi destroy --stack dev --yes)
kind delete cluster --name pulumi-dev-cp
```

See `SETUP.md` for setup from scratch and troubleshooting.
