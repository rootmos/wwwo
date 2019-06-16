type t = CalendarLib.Date.t

let wrap s =
  try CalendarLib.Printer.Date.from_fstring "%F" s
  with Invalid_argument _ ->
  CalendarLib.Printer.Date.from_fstring "%FT%T%:z" s

let unwrap t = CalendarLib.Printer.Date.sprint "%a, %d %b %Y" t

let rfc822 t = CalendarLib.Printer.Date.sprint "%a, %d %b %Y" t
let compare t t' = CalendarLib.Date.compare t t'
