FROM alpine:3.18.4

RUN apk update && apk add \
    bash make gcc musl-dev \
    python3 \
    opam \
    git \
    tidyhtml

WORKDIR /workdir

COPY GNUmakefile requirements.txt .
RUN make .flag.requirements.txt

RUN opam init --bare --disable-sandboxing --shell-setup
RUN opam switch create default 4.14.1

COPY src/deps /tmp/deps
RUN xargs opam install --yes < /tmp/deps && rm /tmp/deps

RUN make fa

COPY bin bin

COPY src src
RUN eval $(opam env) && make build

ENTRYPOINT [ "/workdir/bin/rebuild.sh" ]
