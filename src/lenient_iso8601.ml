open CalendarLib
type t = Calendar.t

let wrap s =
  try Printer.Calendar.from_fstring "%F" s
  with Invalid_argument _ ->
  try Printer.Calendar.from_fstring "%FT%TZ"
    (Str.global_replace (Str.regexp "\\.[0-9]+") "" s)
  with Invalid_argument _ ->
  try Printer.Calendar.from_fstring "%FT%T%:z"
    (Str.global_replace (Str.regexp "\\.[0-9]+") "" s)
  with Invalid_argument _ ->
  try Printer.Calendar.from_fstring "%FT%T%:z"
    (Str.global_replace (Str.regexp "T\\([0-9]+\\):\\([0-9]+\\)\\+") "T\\1:\\2:00+" s)
  with Invalid_argument _ ->
  let d = Printer.Date.from_fstring "%F" s in
    Calendar.create d (Time.midday ())

let unwrap t = Printer.Calendar.sprint "%a, %d %b %Y" t

let rfc822 t = Printer.Calendar.sprint "%a, %d %b %Y" t
let compare t t' = Calendar.compare t t'

module Date = struct
  type z = t
  type t = z
  let compare t t' = Date.compare (Calendar.to_date t) (Calendar.to_date t')
  let iso8601 t = Printer.Date.sprint "%F" (Calendar.to_date t)
end
