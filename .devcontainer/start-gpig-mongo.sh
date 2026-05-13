#!/usr/bin/env bash
set -euo pipefail

container_name="${GPIG_MONGO_CONTAINER_NAME:-mongo-gpig-audit}"
volume_name="${GPIG_MONGO_VOLUME_NAME:-gpig-mongo-data}"
image_name="${GPIG_MONGO_IMAGE:-mongo:8.0}"
mongo_user="${GPIG_MONGO_USER:-gpig}"
mongo_password="${GPIG_MONGO_PASSWORD:-gpig}"
mongo_database="${GPIG_MONGO_DATABASE:-gpig_audit}"

if ! command -v docker >/dev/null 2>&1; then
  echo "[gpig] Docker CLI is not available; MongoDB container was not started."
  exit 0
fi

for _ in $(seq 1 60); do
  if docker info >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

if ! docker info >/dev/null 2>&1; then
  echo "[gpig] Docker daemon is not ready; MongoDB container was not started."
  exit 0
fi

docker volume create "${volume_name}" >/dev/null

if docker container inspect "${container_name}" >/dev/null 2>&1; then
  docker start "${container_name}" >/dev/null
else
  docker run -d \
    --name "${container_name}" \
    --restart unless-stopped \
    -e "MONGO_INITDB_ROOT_USERNAME=${mongo_user}" \
    -e "MONGO_INITDB_ROOT_PASSWORD=${mongo_password}" \
    -e "MONGO_INITDB_DATABASE=${mongo_database}" \
    -p 127.0.0.1:27017:27017 \
    -v "${volume_name}:/data/db" \
    "${image_name}" >/dev/null
fi

for _ in $(seq 1 60); do
  if docker exec "${container_name}" mongosh \
    --quiet \
    --username "${mongo_user}" \
    --password "${mongo_password}" \
    --authenticationDatabase admin \
    --eval 'db.adminCommand({ ping: 1 }).ok' >/dev/null 2>&1; then
    echo "[gpig] MongoDB container is running on 127.0.0.1:27017."
    exit 0
  fi
  sleep 1
done

echo "[gpig] MongoDB container started, but did not become healthy in time."
