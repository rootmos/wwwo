open Html

let page = () |> html @@ seq [
    head @@ seq [
        title "Hello";
    ];
    body @@ seq [
        h1 @@ text "Hello";
    ];
]

let () = Utils.write_file "hello.html" page
