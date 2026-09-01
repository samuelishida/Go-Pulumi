#!/usr/bin/env bash

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

NAME="${CLUSTER_NAME:-pulumi-dev-cp}"
CONTAINER="${NAME}-control-plane"

if docker ps -a --format '{{.Names}}' | grep -qx "$CONTAINER"; then
  echo "stopping cluster $NAME"
  docker stop "$CONTAINER" >/dev/null
  echo "cluster stopped"
else
  echo "cluster $NAME not running"
fi
