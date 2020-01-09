open CalendarLib
type t = Calendar.t

let wrap s =
  try Printer.Calendar.from_fstring "%F" s
  with Invalid_argument _ ->
  try Printer.Calendar.from_fstring "%FT%TZ" s
  with Invalid_argument _ ->
  try Printer.Calendar.from_fstring "%FT%T%:z" s
  with Invalid_argument _ ->
  let d = Printer.Date.from_fstring "%F" s in
  Calendar.create d (Time.midday ())

let unwrap t = Printer.Calendar.sprint "%a, %d %b %Y" t

let rfc822 t = Printer.Calendar.sprint "%a, %d %b %Y" t
let compare t t' = Calendar.compare t t'
