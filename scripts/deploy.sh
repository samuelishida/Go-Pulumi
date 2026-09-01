#!/usr/bin/env bash
set -e

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

if [ -d .tools/go/bin ]; then
  export PATH="$PWD/.tools/go/bin:$PWD/.tools/bin:$PATH"
fi

STACK="${1:-dev}"

[ -n "${PULUMI_BACKEND_URL:-}" ] || (echo "set PULUMI_BACKEND_URL" && exit 1)
case "$PULUMI_BACKEND_URL" in
  file://*) mkdir -p "${PULUMI_BACKEND_URL#file://}" ;;
esac
command -v pulumi >/dev/null || (echo "run scripts/bootstrap.sh first" && exit 1)

cd infra

pulumi stack select "$STACK" 2>/dev/null || pulumi stack init "$STACK"

echo "pulumi preview $STACK"
pulumi preview --stack "$STACK" --diff --refresh

printf 'deploy? [y/N] '
read -r answer
[ "$answer" = "y" ] || [ "$answer" = "Y" ] || exit 1

echo "pulumi up $STACK"
pulumi up --stack "$STACK" --refresh --yes

echo "stack $STACK deployed"