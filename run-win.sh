#!/bin/sh

## idea is here to make a run script which
## makes the necessary substitutes for windows
## 
## relative paths are now already handled with ${PWD}
## sed -e "s@\./@$(pwd)/@g"

sed -e "s/localhost/$(docker-machine ip)/g" docker-compose.yml | docker-compose --file - up "$@"


## Create a new docker compose file for win:

# sed -e "s/localhost/$(docker-machine ip)/g" docker-compose.yml | sed -e "s@\./@$(pwd)/@g"

## We can use this to create the necessary docker-compose file with
##   ./run-win.sh > dcwin.yml
## and then use that with
##   docker-compose -f dcwin.yml up --build --no-color
