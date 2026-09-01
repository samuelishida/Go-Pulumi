#!/usr/bin/env bash
set -e

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

if [ -d .tools/bin ]; then
  export PATH="$PWD/.tools/go/bin:$PWD/.tools/bin:$PATH"
fi

STACK="${1:-dev}"
NAME="${CLUSTER_NAME:-pulumi-dev-cp}"

[ -n "${PULUMI_BACKEND_URL:-}" ] || (echo "set PULUMI_BACKEND_URL" && exit 1)

if command -v pulumi >/dev/null && [ -d infra ]; then
  echo "destroy stack $STACK"
  (cd infra && pulumi destroy --stack "$STACK" --yes)
fi

if kind get clusters 2>/dev/null | grep -qx "$NAME"; then
  echo "delete cluster $NAME"
  kind delete cluster --name "$NAME"
fi

if docker ps -a --format '{{.Names}}' | grep -qx kind-registry; then
  echo "remove registry"
  docker rm -f kind-registry >/dev/null
fi

echo "done"
