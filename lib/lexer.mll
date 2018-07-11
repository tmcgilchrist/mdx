{

open Astring
open S

let pp_position ppf lexbuf =
  let p = Lexing.lexeme_start_p lexbuf in
  Fmt.pf ppf
    "File \"%s\", line %d, character %d"
    p.Lexing.pos_fname p.Lexing.pos_lnum
    (p.Lexing.pos_cnum - p.Lexing.pos_bol)

(* TODO: better error reporting *)
let err lexbuf fmt =
  Fmt.kstrf (fun str ->
      Fmt.failwith "%a: %s" pp_position lexbuf str
    ) fmt

let line_ref = ref 1

let newline lexbuf =
  Lexing.new_line lexbuf;
  incr line_ref

let commands s = String.cuts ~sep:"\\\n> " s

}

let eol = '\n' | eof
let ws = ' ' | '\t'
let cram_cmd = [^'\n' '\\']+ ("\\\n> " [^'\n' '\\'] +)*
let digit = ['0' - '9']

rule text section = parse
  | eof { [] }
  | ("#"+ as n) " " ([^'\n']* as str) eol
      { let section = (String.length n, str) in
        newline lexbuf;
        Section section :: text (Some section) lexbuf }
  | "```" ([^' ' '\n']* as h) ws* ([^'\n']* as l) eol
      { let header = if h = "" then None else Some h in
        let contents = block lexbuf in
        let labels = String.cuts ~empty:false ~sep:"," l in
        let value = Raw in
        let file = lexbuf.Lexing.lex_start_p.Lexing.pos_fname in
        newline lexbuf;
        let line = !line_ref in
        List.iter (fun _ -> newline lexbuf) contents;
        newline lexbuf;
        Block { file; line; section; header; contents; labels; value }
        :: text section lexbuf }
  | ([^'\n']* as str) eol
      { newline lexbuf;
        Text str :: text section lexbuf }

and block = parse
  | eol | "```" ws* eol    { [] }
  | ([^'\n'] * as str) eol { str :: block lexbuf }

and cram = parse
 | eol                             { [] }
 | "[" (digit+ as str) "]" ws* eol { `Exit (int_of_string str) :: cram lexbuf }
 | "..." ws* eol                   { `Ellipsis :: cram lexbuf }
 | "$ " (cram_cmd as str) eol      { `Command (commands str) :: cram lexbuf }
 | ([^'\n']* as str) eol           { `Output str :: cram lexbuf }

and toplevel = parse
 | eof           { [] }
 | "..." ws* eol { `Ellipsis :: toplevel lexbuf }
 | "# "          { let c = phrase [] (Buffer.create 8) lexbuf in
                   `Command c :: toplevel lexbuf }
 | ([^'#'] [^'\n']* as str) eol { `Output  str :: toplevel lexbuf }

and phrase acc buf = parse
  | "\n  "
      { Lexing.new_line lexbuf;
        phrase (Buffer.contents buf :: acc) (Buffer.create 8) lexbuf }
  | eol
      { Lexing.new_line lexbuf;
        List.rev (Buffer.contents buf :: acc) }
 | ";;" eol { List.rev ((Buffer.contents buf ^ ";;") :: acc) }
 | _ as c   { Buffer.add_char buf c; phrase acc buf lexbuf }

{

let token lexbuf =
  try text None lexbuf
  with Failure _ -> err lexbuf "incomplete code block"

let toplevel lexbuf =
  try toplevel lexbuf
  with Failure _ -> err lexbuf "incomplete toplevel"

let cram lexbuf =
  try cram lexbuf
  with Failure _ -> err lexbuf "incomplete cram test"

}
