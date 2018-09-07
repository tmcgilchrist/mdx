(*
 * Copyright (c) 2018 Thomas Gazagnaire <thomas@gazagnaire.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *)

let src = Logs.Src.create "cram.promote"
module Log = (val Logs.src_log src : Logs.LOG)

let (/) x y = match x with
  | "." -> y
  | _   -> Filename.concat x y

let run () _ _ _ _ _ _ _ _ _ =
  let base = Filename.basename Sys.argv.(0) in
  let dir = Filename.dirname Sys.argv.(0) in
  let cmd = match base with
    | "main.exe" -> dir / "promote" / "main.exe"
    | x -> dir / x ^ "-promote"
  in
  let argv = Array.sub Sys.argv 1 (Array.length Sys.argv - 1) in
  argv.(0) <- cmd;
  Log.debug (fun l -> l "executing %a" Fmt.(Dump.array string) argv);
  Unix.execvp cmd argv

open Cmdliner

let cmd: int Term.t * Term.info =
  let doc = "Promote the contents of files to markdown." in
  Term.(pure run
        $ Cli.setup $ Cli.non_deterministic $ Cli.not_verbose
        $ Cli.silent $ Cli.verbose_findlib $ Cli.prelude $ Cli.prelude_str
        $ Cli.file $ Cli.section $ Cli.root),
  Term.info "promote" ~doc
