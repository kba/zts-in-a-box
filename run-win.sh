#!/bin/sh

## idea is here to make a run script which
## makes the necessary substitutes for windows



## TODO this is not really working...

#DCWIN="$(sed -e 's/localhost/$(docker-machine ip)/g' docker-compose.yml | sed -e 's@\./@$(pwd)/@g')"
#echo $DCWIN
#docker-compose -f $DCWIN up "$@"



## Something which works:

sed -e "s/localhost/$(docker-machine ip)/g" docker-compose.yml | sed -e "s@\./@$(pwd)/@g"

## We can use this to create the necessary docker-compose file with
##   ./run-win.sh > dcwin.yml
## and then use that with
##   docker-compose -f dcwin.yml up --build --no-color
