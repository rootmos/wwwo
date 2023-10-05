FROM alpine:3.18.4

RUN apk update && apk add \
    bash make gcc musl-dev \
    opam \
    python3 py3-pip \
    g++ cmake autoconf automake libtool elfutils-dev python3-dev \
    wget rsync tidyhtml

WORKDIR /workdir

# fortawesome
COPY bin/fontawesome bin/fetch.sh bin/
RUN bin/fontawesome

# ocaml: prepare
COPY bin/buildml /usr/bin/

# ocaml: switch
ENV OPAMROOTISOK=1
ENV OPAMNOSANDBOXING=1
COPY generator/switch generator/
RUN buildml -C generator -s

# ocaml: deps
COPY generator/deps generator/
RUN buildml -C generator -d

# python: prepare
COPY bin/python* bin/

# python; deps: lambda
COPY lambda/Pipfile lambda/Pipfile.lock lambda/pyproject.toml lambda/setup.cfg lambda/
RUN bin/python-deps lambda

# python; deps: meta
COPY meta/Pipfile meta/Pipfile.lock meta/pyproject.toml meta/setup.cfg meta/
RUN bin/python-deps meta

# ocaml: install
COPY generator/Makefile generator/
COPY generator/src generator/src
RUN buildml -C generator -m install

# python; install: meta
COPY meta/src meta/src
RUN bin/python-install meta

# content
COPY generate meta.mk .
COPY content content

# python; install: lambda
COPY lambda/src lambda/src
RUN bin/python-install lambda

ENTRYPOINT [ "/usr/bin/wwwo-lambda", "-C", "/workdir" ]
