#!/usr/bin/env bash

set -o errexit
set -o nounset

sudo mkdir -p /srv/raha/mysql
sudo mkdir -p /srv/raha/logs
sudo mkdir -p /srv/raha/config

docker stop raha || true
docker rm raha || true

docker run --interactive --tty \
    --hostname raha \
    --name raha \
    --volume /srv/raha/mysql:/var/lib/mysql \
    --volume /srv/raha/logs:/var/log \
    --volume /srv/raha/config:/var/www/raha/config \
    --publish 8080:8080 \
    --env MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD}" \
    --env TZ=Europe/Tallinn \
    --volume /etc/timezone:/etc/timezone:ro \
    --volume /etc/localtime:/etc/localtime:ro \
    dhirajpatra/raha:latest bash
