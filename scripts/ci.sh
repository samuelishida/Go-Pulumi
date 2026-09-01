#!/usr/bin/env bash
set -e

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

if [ -d .tools/go/bin ]; then
  export PATH="$PWD/.tools/go/bin:$PWD/.tools/bin:$PATH"
fi

IMAGE="${IMAGE:-localhost:5001/echo-service:ci}"

command -v go >/dev/null || (echo "run scripts/bootstrap.sh first" && exit 1)
command -v docker >/dev/null || (echo "docker is required" && exit 1)

echo "go test"
cd app && go test ./...
cd ..

echo "docker build $IMAGE"
docker build -t "$IMAGE" app

if [ "${SKIP_PUSH:-0}" = "1" ]; then
  echo "skip push"
  exit 0
fi

REGISTRY_PORT="${IMAGE%%/*}"
REGISTRY_PORT="${REGISTRY_PORT##*:}"
if [[ "${IMAGE%%/*}" == localhost:* ]] && ! curl -fsS "http://localhost:$REGISTRY_PORT/v2/" >/dev/null 2>&1; then
  echo "starting local registry"
  docker run -d --restart=always -p "127.0.0.1:$REGISTRY_PORT:5000" --name kind-registry registry:2 >/dev/null 2>&1 || true
fi

echo "push $IMAGE"
docker push "$IMAGE"
echo "pushed"