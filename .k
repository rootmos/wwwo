export PORT=8000
export BASE_URL=http://localhost:$PORT

#export BUILDML_OCAMLC_OPTS=-g
#export OCAMLRUNPARAM=b

POST=${POST-"the-journey"}

post() {
    export WWWO_ENV=dev
    gen_post \
        -src "$K_DIR/content/post/$POST.md" \
        -content "$K_DIR/content" \
        -output "$K_DIR/workdir/webroot/dev/$POST.html"
}

gen_post() {
    bin/buildml -C generator -m build && \
        bin/buildml -C generator -e src/gen_post.exe "$@"
}

serve() {
    bin/serve workdir/webroot/dev
}

go() {
    bin/buildml -C generator -m && ./generate -w workdir -e dev
}

fa() {
    rm -rf workdir/fa
    ./generate -w workdir -e dev
}

upload() {
    aws s3 cp --acl=public-read "workdir/webroot/dev/$POST.html" "s3://rootmos-www/$POST.html"
}
