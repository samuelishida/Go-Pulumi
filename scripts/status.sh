#!/usr/bin/env bash

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

if [ -d .tools/bin ]; then
  export PATH="$PWD/.tools/go/bin:$PWD/.tools/bin:$PATH"
fi

NAME="${CLUSTER_NAME:-pulumi-dev-cp}"

if ! kind get clusters 2>/dev/null | grep -qx "$NAME"; then
  echo "cluster $NAME does not exist"
  exit
fi

if docker ps -a --format '{{.Names}} {{.State}}' | grep -q "^${NAME}-control-plane exited"; then
  echo "cluster $NAME is stopped"
  exit
fi

echo "nodes"
kubectl get nodes

echo "deployment"
kubectl get deployment echo -o wide

echo "pods"
kubectl get pods -l app=echo -o wide

echo "service"
kubectl get svc echo -o wide

echo "endpoints"
kubectl get endpoints echo
