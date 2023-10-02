FROM alpine:3.18.4

RUN apk update
RUN apk add bash make gcc musl-dev

WORKDIR /workdir

RUN apk add python3
COPY GNUmakefile requirements.txt .

RUN make .flag.requirements.txt

RUN apk add opam

RUN opam init --bare --disable-sandboxing --shell-setup
RUN opam switch create default 4.14.1

COPY src/deps /tmp/deps
RUN xargs opam install --yes < /tmp/deps && rm /tmp/deps

COPY src src
#RUN make build

#RUN apk add tidy

#RUN make build
