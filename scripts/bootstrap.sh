#!/usr/bin/env bash
set -e

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

CREATE_CLUSTER=0
for arg in "$@"; do
  case "$arg" in
    --cluster) CREATE_CLUSTER=1 ;;
    *) echo "usage: $0 [--cluster]"; exit 1 ;;
  esac
done

TOOLS="$PWD/.tools"
BIN="$TOOLS/bin"
mkdir -p "$BIN"

CLUSTER_NAME="${CLUSTER_NAME:-pulumi-dev-cp}"
REGISTRY_NAME="kind-registry"
REGISTRY_PORT=5001

GO_VERSION="1.25.0"
KIND_VERSION="v0.24.0"
KUBECTL_VERSION="v1.31.1"
PULUMI_VERSION="v3.146.0"

ARCH="$(uname -m)"
case "$ARCH" in
  x86_64) GO_ARCH="amd64"; PULUMI_ARCH="x64" ;;
  aarch64) GO_ARCH="arm64"; PULUMI_ARCH="arm64" ;;
  *) echo "unsupported arch: $ARCH"; exit 1 ;;
esac

command -v curl >/dev/null || (echo "curl is required" && exit 1)
command -v docker >/dev/null || (echo "docker is required" && exit 1)
docker info >/dev/null || (echo "docker daemon not running" && exit 1)

GO_HOME="$TOOLS/go"
if [ ! -x "$GO_HOME/bin/go" ]; then
  tarball="go${GO_VERSION}.linux-${GO_ARCH}.tar.gz"
  echo "download go $GO_VERSION"
  curl -fsSL "https://go.dev/dl/${tarball}" -o "/tmp/${tarball}"
  rm -rf "$GO_HOME"
  tar -C "$TOOLS" -xzf "/tmp/${tarball}"
  rm -f "/tmp/${tarball}"
fi
export PATH="$GO_HOME/bin:$BIN:$PATH"

if [ ! -x "$BIN/kind" ]; then
  echo "download kind"
  curl -fsSL "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-${GO_ARCH}" -o "$BIN/kind"
  chmod +x "$BIN/kind"
fi

if [ ! -x "$BIN/kubectl" ]; then
  echo "download kubectl"
  curl -fsSL "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${GO_ARCH}/kubectl" -o "$BIN/kubectl"
  chmod +x "$BIN/kubectl"
fi

if [ ! -x "$BIN/pulumi" ]; then
  echo "download pulumi $PULUMI_VERSION"
  rm -rf /tmp/pulumi-extract
  mkdir -p /tmp/pulumi-extract
  curl -fsSL "https://get.pulumi.com/releases/sdk/pulumi-${PULUMI_VERSION}-linux-${PULUMI_ARCH}.tar.gz" | tar -xz -C /tmp/pulumi-extract
  cp /tmp/pulumi-extract/pulumi/* "$BIN/"
  rm -rf /tmp/pulumi-extract
fi

echo "versions"
go version
"$BIN/kind" version
"$BIN/kubectl" version --client
"$BIN/pulumi" version

if [ "$CREATE_CLUSTER" -eq 0 ]; then
  echo ""
  echo "tools ready. run with --cluster to create cluster"
  exit 0
fi

if ! curl -fsS "http://localhost:${REGISTRY_PORT}/v2/" >/dev/null 2>&1; then
  if docker ps -a --format '{{.Names}}' | grep -qx "$REGISTRY_NAME"; then
    echo "start registry"
    docker start "$REGISTRY_NAME" >/dev/null
  else
    echo "create registry"
    docker run -d --restart=always -p "127.0.0.1:${REGISTRY_PORT}:5000" --name "$REGISTRY_NAME" registry:2 >/dev/null
  fi
  for _ in $(seq 1 20); do
    curl -fsS "http://localhost:${REGISTRY_PORT}/v2/" >/dev/null 2>&1 && break
    sleep 0.5
  done
fi

if kind get clusters 2>/dev/null | grep -qx "$CLUSTER_NAME"; then
  echo "cluster $CLUSTER_NAME already exists"
else
  echo "create cluster $CLUSTER_NAME"
  kind create cluster --config kind-config.yaml
fi
kind export kubeconfig --name "$CLUSTER_NAME"
docker network connect kind "$REGISTRY_NAME" 2>/dev/null || true

echo "cluster $CLUSTER_NAME ready"
echo ""
echo "export PATH=\"$PWD/.tools/go/bin:$PWD/.tools/bin:\$PATH\""