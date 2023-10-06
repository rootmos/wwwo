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



FROM alpine:3.18.4 as meta-builder

RUN apk update && apk add bash python3 py3-pip

WORKDIR /workdir

COPY bin/buildpy /usr/bin/

RUN buildpy -p

COPY meta/Pipfile meta/Pipfile.lock meta/pyproject.toml meta/
RUN buildpy -C meta -d

COPY meta/src meta/src
RUN buildpy -C meta -b -T /meta.tar.gz



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
    python3 wget make rsync tidyhtml

WORKDIR /workdir

COPY bin/fontawesome bin/fetch.sh bin/
RUN bin/fontawesome

COPY --from=lambda-builder /lambda.tar.gz /
RUN tar xf /lambda.tar.gz -C /

COPY --from=meta-builder /meta.tar.gz /
RUN tar xf /meta.tar.gz -C /

COPY --from=generator-builder /usr/bin/wwwo-generator /usr/bin/wwwo-generator

COPY generate meta.mk .
COPY content content

ENTRYPOINT [ "/usr/bin/wwwo-lambda", "-C", "/workdir" ]
