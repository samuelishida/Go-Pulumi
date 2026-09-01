#!/usr/bin/env bash

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

if [ -d .tools/bin ]; then
  export PATH="$PWD/.tools/go/bin:$PWD/.tools/bin:$PATH"
fi

NAME="${CLUSTER_NAME:-pulumi-dev-cp}"
CONTAINER="${NAME}-control-plane"

if docker ps -a --format '{{.Names}}' | grep -qx "$CONTAINER"; then
  echo "starting cluster $NAME"
  docker start "$CONTAINER" >/dev/null
else
  echo "cluster $NAME not found"
  exit 1
fi

for _ in $(seq 1 30); do
  if kubectl get nodes >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

kubectl get nodes

if kubectl get svc echo >/dev/null 2>&1; then
  echo "refresh endpoints"
  kubectl delete endpoints echo >/dev/null 2>&1 || true
  sleep 2
fi

echo "cluster $NAME ready"
