FROM alpine:3.18.4 as generator-builder

RUN apk update && apk add bash make gcc musl-dev opam

WORKDIR /workdir

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

# ocaml: install
COPY generator/Makefile generator/
COPY generator/src generator/src
RUN buildml -C generator -m install



FROM alpine:3.18.4 as tasks-builder

RUN apk update && apk add bash python3 py3-pip

WORKDIR /workdir

COPY bin/buildpy /usr/bin/

RUN buildpy -p

COPY tasks/Pipfile tasks/Pipfile.lock tasks/pyproject.toml tasks/
RUN buildpy -C tasks -d

COPY tasks/src tasks/src
RUN buildpy -C tasks -b -T /tasks.tar.gz



FROM alpine:3.18.4 as lambda-builder

RUN apk update && apk add bash \
    python3-dev py3-pip \
    make gcc musl-dev g++ cmake autoconf automake libtool elfutils-dev

WORKDIR /workdir

COPY bin/buildpy /usr/bin/

RUN buildpy -p

COPY lambda/Pipfile lambda/Pipfile.lock lambda/pyproject.toml lambda/
RUN buildpy -C lambda -d

COPY lambda/src lambda/src
RUN buildpy -C lambda -b -T /lambda.tar.gz



FROM alpine:3.18.4

RUN apk update && apk add bash \
    python3 wget make rsync tidyhtml libmagic

WORKDIR /workdir

COPY bin/fontawesome bin/fetch.sh bin/
RUN bin/fontawesome

COPY --from=lambda-builder /lambda.tar.gz /
RUN tar xf /lambda.tar.gz -C /

COPY --from=tasks-builder /tasks.tar.gz /
RUN tar xf /tasks.tar.gz -C /

COPY --from=generator-builder /usr/bin/wwwo-generator /usr/bin/wwwo-generator

COPY generate meta.mk .
COPY content content

ENTRYPOINT [ "/usr/bin/wwwo-lambda", "-C", "/workdir" ]
