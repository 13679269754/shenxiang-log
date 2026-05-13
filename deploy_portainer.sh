#!/bin/bash

# Configuration
CONTAINER_NAME="portainer"
PORT_HTTP=9001
PORT_HTTPS=9444
DATA_VOLUME="portainer_data"

echo "Checking if $CONTAINER_NAME container exists..."
if [ "$(docker ps -a -f name=^/${CONTAINER_NAME}$ --format '{{.Names}}')" == "$CONTAINER_NAME" ]; then
    echo "Portainer container exists. Checking status..."
    if [ "$(docker ps -f name=^/${CONTAINER_NAME}$ --format '{{.Status}}' | grep Up)" ]; then
        echo "Portainer is already running."
    else
        echo "Portainer is stopped. Starting it..."
        docker start $CONTAINER_NAME
    fi
else
    echo "Portainer container does not exist. Deploying..."
    
    # Create volume if it doesn't exist
    docker volume create $DATA_VOLUME
    
    # Deploy Portainer
    docker run -d \
      -p $PORT_HTTP:9000 \
      -p $PORT_HTTPS:9443 \
      --name $CONTAINER_NAME \
      --restart=always \
      -v /var/run/docker.sock:/var/run/docker.sock \
      -v $DATA_VOLUME:/data \
      portainer/portainer-ce:latest
      
    echo "Portainer deployed successfully."
fi

echo "Verifying deployment..."
docker ps -f name=^/${CONTAINER_NAME}$
