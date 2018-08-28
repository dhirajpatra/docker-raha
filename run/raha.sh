#!/usr/bin/env bash

set -o errexit
set -o nounset

# Create mount points
sudo mkdir -p /srv/raha/mysql
sudo mkdir -p /srv/raha/logs
sudo mkdir -p /srv/raha/config

# Stop the running container
docker stop raha || true

# Remove existing container
docker rm raha || true

# Pull the new image
docker pull dhirajpatra/docker-raha:latest

# Run the container
docker run --detach --init \
    --hostname raha \
    --name raha \
    --restart always \
    --publish 8080:8080 \
    --volume /srv/raha/mysql:/var/lib/mysql \
    --volume /srv/raha/logs:/var/log \
    --volume /srv/raha/config:/var/www/raha/config \
    --env MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD}" \
    --env TZ=Europe/Tallinn \
    --volume /etc/timezone:/etc/timezone:ro \
    --volume /etc/localtime:/etc/localtime:ro \
    dhirajpatra/docker-raha:latest
