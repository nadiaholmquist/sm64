FROM devkitpro/devkitarm:latest as build

RUN apt update
RUN apt -y install build-essential bsdmainutils
RUN mkdir /sm64
WORKDIR /sm64

CMD echo 'usage: ddocker run --rm --mount type=bind,source="$(pwd)",destination=/sm64 sm64dsi make VERSION=us COMPILER=gcc -j4\nocker run --rm --mount type=bind,source="$(pwd)",destination=/sm64 sm64dsi make VERSION=us COMPILER=gcc -j4\n' \
         'see https://github.com/n64decomp/sm64/blob/master/README.md for advanced usage'
