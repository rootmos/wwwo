type t = Timedesc.t

let wrap = Timedesc.of_iso8601_exn
let unwrap = Timedesc.to_iso8601

let compare = Timedesc.compare_chrono_min

let rfc5322_min t =
    let format = "{wday:Xxx}, {day:X} {mon:Xxx} {year} {hour:0X}:{min:0X} {tzoff-sign}{tzoff-hour:0X}:{tzoff-min:0X}" in
    Timedesc.to_string ~format t
