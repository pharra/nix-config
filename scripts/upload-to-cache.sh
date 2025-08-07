#!/bin/sh

# https://nix.dev/manual/nix/2.19/advanced-topics/post-build-hook
set -eu

# if NIX_CACHE_URL is not set, exit
if [ -z "$OUT_PATHS:-}" ]; then
    echo "NIX_CACHE_URL is not set, skipping upload to cache."
    exit 0
fi

echo "attic push main $OUT_PATHS"

# attic push main $OUT_PATHS