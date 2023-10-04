FROM alpine:3.18.4 as ocaml-builder

RUN apk update && apk add bash make opam gcc musl-dev

COPY bin/buildml /usr/bin/

WORKDIR /workdir

ENV OPAMROOTISOK=1
ENV OPAMNOSANDBOXING=1

COPY generator/switch .
RUN buildml -s

COPY generator/deps .
RUN buildml -d

COPY generator/Makefile .
COPY generator/src src
RUN buildml -m install

# main build
FROM alpine:3.18.4

RUN apk update && apk add \
    bash make gcc musl-dev \
    python3 py3-pip \
    g++ cmake autoconf automake libtool elfutils-dev python3-dev \
    tidyhtml

WORKDIR /workdir

COPY bin/python-* bin/

# python deps

COPY bin/python* bin/

COPY meta/Pipfile meta/Pipfile.lock meta/pyproject.toml meta/setup.cfg meta/
RUN bin/python-deps meta

COPY lambda/Pipfile lambda/Pipfile.lock lambda/pyproject.toml lambda/setup.cfg lambda/
RUN bin/python-deps lambda

# build and install

COPY meta/src meta/src
RUN bin/python-install meta

COPY lambda/src lambda/src
RUN bin/python-install lambda

COPY --from=ocaml-builder /usr/bin/wwwo-generator /usr/bin/wwwo-generator

# RUN make fa

ENTRYPOINT [ "/usr/bin/wwwo-lambda" ]
