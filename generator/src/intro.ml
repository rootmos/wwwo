open Html

open struct
  let social = seq @@ List.rev [
    a "https://github.com/rootmos" @@ svg ~cls:"social" "fa/svgs/brands/github.svg";
    a "https://git.sr.ht/~rootmos" @@ svg ~cls:"social" (Path.image "sourcehut.svg");
    a "https://keybase.io/rootmos" @@ svg ~cls:"social" "fa/svgs/brands/keybase.svg";
    a "https://twitch.tv/rootmos2" @@ svg ~cls:"social" "fa/svgs/brands/twitch.svg";
    a "https://soundcloud.com/rootmos" @@ svg ~cls:"social" "fa/svgs/brands/soundcloud.svg";
  ]

  let slogan = div ~cls:(Some "slogan") @@ seq [
    text "Some ";
    a "#math" @@ text "math";
    text ", ";
    a "#music" @@ text "music";
    text ", mostly ";
    a "#programming" @@ text "programming";
    text " and everything in between";
  ]

  let rootmos_definition =
    div ~cls:(Some "explanation") @@ seq [
      text "rootmos := conflation of ";
      a "https://en.wikipedia.org/wiki/Superuser" @@ text "root";
      text " and ";
      a "https://sv.wikipedia.org/wiki/Rotmos" @@ text "rotmos";
    ]

  let sloth_explanation conj =
    div ~cls:(Some "explanation") @@ seq [
      text @@ conj ^ " what's with the";
      text " ";
      a "https://knowyourmeme.com/memes/astronaut-sloth" @@ text "sloth";
      text "?";
    ]

  let trust obj trust verify = div ~cls:(Some "text") @@ seq [
    text obj; text " ";
    a ~alt:(Some "Reflections on trusting trust, Ken Thompson") "https://dl.acm.org/doi/10.1145/358198.358210" @@ text trust;
    text ",&nbspbut ";
    a "https://en.wikipedia.org/wiki/Trust,_but_verify" @@ text verify;
  ]

  let separator = div ~cls:(Some "separator") @@ noop

  let description = function
  | 0 -> [
    slogan;
    separator;
    rootmos_definition;
  ]
  | 1 -> [
    slogan;
    separator;
    rootmos_definition;
    trust "I" "trust" "verify";
    separator;
    sloth_explanation "but";
  ]
  | 2 -> [
    slogan;
    separator;

    rootmos_definition;
    div ~cls:(Some "text") @@ text "a problem-solving automaton";
    trust "that" "trusts" "verifies";
    separator;

    div ~cls:(Some "text") @@ seq [
      text "I like ";
      a "https://github.com/rootmos/silly-k" @@ text "silly";
      text " things and ";
      a "https://en.wikipedia.org/w/index.php?title=Surreal_Numbers_(book)" @@ text "surreal";
      text " non-sense";
    ];
    div ~cls:(Some "text") @@ text "but I'm dead serious about code and ruthlessly (self-)critical";
    separator;

    div ~cls:(Some "text") @@ seq [
      text "oh, and yes I'm ";
      a "https://unixgreybeard.com/" @@ text "that guy";
      text ":";
    ];
    div ~cls:(Some "text") @@ seq [
      a "https://archlinux.org/" @@ text "Arch Linux";
      text ", ";
      a "https://github.com/rootmos/desktop" @@ text ".";
      text "&thinsp;";
      a "https://xmonad.org/" @@ text "XMonad";
      text ", ";
      a "https://en.wikipedia.org/wiki/Kinesis_(keyboard)#Contoured_/_Advantage" @@ text "Kinesis";
      text ", ";
      a "https://github.com/rootmos/dvorak" @@ text "custom";
      text " ";
      a "https://en.wikipedia.org/wiki/Dvorak_keyboard_layout" @@ text "Dvorak";
      text " and ";
      a "https://git.sr.ht/~rootmos/dot-nvim" @@ text ".";
      text "&thinsp;";
      a "https://neovim.io/" @@ text "nvim";
    ];
    separator;

    sloth_explanation "and";
  ]
  | _ -> failwith "undefined variant"

  let picture = function
    0 -> img ~cls:(Some "portrait") ~alt:(Some "Gustav Behm") (Path.image "portrait.jpg")
  | _ ->
    let acronym = "Rolling Oblong Ortofon Troubadouring Mystique Over Salaciousness" in
    img ~cls:(Some "avatar") ~alt:(Some acronym) (Path.image "rootmos.jpg")
end

let make variant = close @@ div ~cls:(Some "intro") @@ seq [
  div ~cls:(Some "row") @@ seq [
    picture variant;
    div ~cls:(Some "description") @@ seq @@ List.rev @@ description variant;
  ];
  div ~cls:(Some "row") @@ seq [ social ];
]
