# Setup

How to spin up the environment from scratch on a machine with Docker.

## Requirements

- Docker running
- bash, curl, jq

## From scratch

```bash
git clone <repo-url> && cd echo-service

export PULUMI_BACKEND_URL="file://$PWD/.pulumi"
export PULUMI_CONFIG_PASSPHRASE=""

scripts/bootstrap.sh --cluster   # installs Go/kind/kubectl/pulumi into .tools/, starts registry, creates kind cluster
scripts/ci.sh                    # unit tests, docker build, push to local registry
scripts/deploy.sh dev            # pulumi preview + up (deploys Deployment + NodePort Service)

curl "http://localhost:30080/hello?a=1" -d 'payload'
```

All scripts are idempotent — safe to re-run.

## What you should see

The curl returns a JSON echo of the request:

```json
{"headers":{...},"params":{"a":["1"]},"body":"payload","path":"/hello"}
```

## Check status

```bash
scripts/status.sh
```

## Tear down

```bash
scripts/teardown.sh
```

## Troubleshooting

- **`ImagePullBackOff` on pods** — the local registry dropped. Run
  `scripts/bootstrap.sh --cluster` again, then
  `kubectl rollout restart deployment echo`.
- **`pulumi` asks for a passphrase** — export `PULUMI_CONFIG_PASSPHRASE=""`
  (local file backend needs no passphrase).
- **Port 30080 busy** — free it, or change the NodePort in `Pulumi.dev.yaml`
  and `kind-config.yaml`, then recreate the cluster.
- **Cluster paused/stopped** — `scripts/start.sh` brings it back and refreshes
  service endpoints.