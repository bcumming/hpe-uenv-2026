#!/bin/bash

set -euo pipefail

cd "$(dirname "$0")"

if command -v docker >/dev/null 2>&1; then
  ocirun=docker
elif command -v podman >/dev/null 2>&1; then
  ocirun=podman
else
  echo "error: neither docker nor podman found in PATH" >&2
  exit 1
fi

# run as the host user so files created in the bind-mounted project
# (node_modules, pnpm store, ...) aren't left owned by root
"$ocirun" run -ti --rm \
  --entrypoint sh \
  --user "$(id -u):$(id -g)" \
  -e HOME=/tmp \
  -e npm_config_prefix=/tmp/.npm-global \
  -v "$PWD":/slides:Z \
  -p 3030:3030 \
  node:22-slim \
  -c 'export PATH="$npm_config_prefix/bin:$PATH" && mkdir -p "$npm_config_prefix/bin" && cd /slides && corepack enable --install-directory "$npm_config_prefix/bin" && pnpm install && pnpm dev --remote -o false'
