#!/bin/bash

LOG_FILE="deploy.log"
git_repo="https://github.com/goga0/backend-fastapi.git"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$$] $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$$] $1" >> "$LOG_FILE"
}

container_name=$(basename $git_repo .git)

if [ ! -d "$container_name" ]; then
    git clone $git_repo
else
    log "Directory $container_name already exists. Skipping clone."
fi

log "Building Docker image: $container_name"
docker build -t $container_name .

docker run -d --name $container_name -p 8000:8000 $container_name
log "Running Docker container: $container_name on port 8000"

for i in {1..4}; do
    health_status=$(docker inspect $container_name --format='{{json .State.Health.Status}}')
    if [ "$health_status" == "\"starting\"" ]; then
        log "Waiting for container $container_name to become healthy..."
        sleep 30
        continue
    elif [ "$health_status" == "\"healthy\"" ]; then
        log "Container $container_name is healthy and running."
        break
    elif [ "$health_status" == "\"unhealthy\"" ]; then
        log "Container $container_name is not healthy after 120 seconds. Check logs for details."
        break
    fi
done

