#!/bin/bash
echo "Building $DEPLOY_ENV"
source .env.$DEPLOY_ENV

docker compose --env-file .env.$DEPLOY_ENV -p accounting-api-fast build
echo "Shutting Down"
docker compose --env-file .env.$DEPLOY_ENV -p accounting-api-fast down
echo "Starting"
docker compose --env-file .env.$DEPLOY_ENV -p accounting-api-fast -f docker-compose.yml up -d --force-recreate
echo "Deleting Unused Images"
if [ -n "$dangling_images" ]; then
  docker rmi $dangling_images -f
else
  echo "No dangling images to delete."
fi
echo "Done"