#!/bin/sh

# run docker-compose
docker-compose up -d --force-recreate

echo "localhost: http://localhost:9992"
echo "done!"
