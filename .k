export PORT=8000
export WWWO_BASE_URL=http://localhost:$PORT

#export BUILDML_OCAMLC_OPTS=-g
#export OCAMLRUNPARAM=b

post() {
    go \
        -src "$K_DIR/content/post/2017-06-08-implementing-a-k-like-language-targeting-malfunction.md" \
        -content "$K_DIR/content" \
        -output "$K_DIR/post.html"
}

go() {
    bin/buildml -C generator -m build && \
        bin/buildml -C generator -e src/gen_post.exe "$@"
}

go2() {
    wwwo-list --prefix="clips" rootmos-static | jq .
}

go1() {
    wwwo-projects content/projects.json
}

go2() {
    bin/buildml -C generator -m && ./generate -w workdir -e dev
}

ecr-login() {
    .github/ecr-login
}

configure() {
    .github/reconfigure-lambda
}

invoke() {
    LAMBDA_TIMEOUT=300 .github/invoke-lambda
}

serve() {
    bin/serve workdir/webroot/dev
}
