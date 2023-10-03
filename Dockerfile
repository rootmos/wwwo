FROM alpine:3.18.4

RUN apk update && apk add \
    bash make gcc musl-dev \
    python3 py3-pip \
    g++ cmake autoconf automake libtool elfutils-dev python3-dev \
    opam \
    tidyhtml

WORKDIR /workdir

# ocmal deps

COPY bin/ocaml-prepare bin/
COPY generator/switch generator/
RUN bin/ocaml-prepare generator

COPY bin/ocaml-deps bin/
COPY generator/deps.* generator/
RUN bin/ocaml-deps generator

# python deps

COPY bin/python* bin/

COPY meta/Pipfile meta/Pipfile.lock meta/pyproject.toml meta/setup.cfg meta/
RUN bin/python-deps meta

COPY lambda/Pipfile lambda/Pipfile.lock lambda/pyproject.toml lambda/setup.cfg lambda/
RUN bin/python-deps lambda

# build

COPY meta/src meta/src
RUN bin/python-install meta

COPY lambda/src lambda/src
RUN bin/python-install lambda

# RUN make fa

ENTRYPOINT [ "/usr/bin/www-lambda" ]
