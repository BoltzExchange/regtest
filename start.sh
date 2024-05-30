#!/bin/bash
set -xe
docker-compose down --volumes
docker-compose up --remove-orphans --build
