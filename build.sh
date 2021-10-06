#!/usr/bin/env bash

set -euo pipefail

image='reitermarkus/csgo'

metamod_version=1.11
sourcemod_version=1.10

docker build -f Dockerfile \
  -t "${image}" \
  .

docker build -f Dockerfile \
  -t "${image}:metamod" \
  --build-arg METAMOD_VERSION="${metamod_version}" \
  .

docker build -f Dockerfile \
  -t "${image}:sourcemod" \
  --build-arg METAMOD_VERSION="${metamod_version}" \
  --build-arg SOURCEMOD_VERSION="${sourcemod_version}" \
  .

docker push "${image}"
docker push "${image}:metamod"
docker push "${image}:sourcemod"
