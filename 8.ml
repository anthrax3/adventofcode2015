#load "str.cma";;

type token =
        Start
        | OpenQuote
        | Quote
        | HexQuote
        | HexQuote_i of string

(* (is)hex are embarrassing. I am embarrassed. *)
let ishex s =
  try ignore (int_of_string ("0x" ^ s)); true
  with _ -> false;;

assert (ishex "4");;
assert (ishex "A");;

let hex a =
        let x = "0x" ^ a in
        String.make 1 (char_of_int (int_of_string x));;

assert ((hex "41") = "A");;
assert ((hex "5a") = "Z");;

let next l r =
        let result, token = l in
        match token, r with
        | Start,        "\"" -> result, OpenQuote
        | Start,        _    -> failwith "unquoted string"
        | OpenQuote,    "\\" -> result, Quote
        | OpenQuote,    "\"" -> result, Start
        | OpenQuote,    v    -> result ^ v, OpenQuote
        | Quote,        "\"" -> result ^ "\"", OpenQuote
        | Quote,        "\\" -> result ^ "\\", OpenQuote
        | Quote,        "x"  -> result, HexQuote
        | Quote,        _    -> failwith "malformed quote"
        | HexQuote,     v when ishex(v) -> result, HexQuote_i v
        | HexQuote,     _    -> failwith "malformed hexquote"
        | HexQuote_i i, v when ishex(v) -> result ^ (hex (i ^ v)), OpenQuote
        | HexQuote_i _, _    -> failwith "malformed hexquote_i";;

assert ((next ("x", Start) "\"") = ("x", OpenQuote));;
assert ((next ("", OpenQuote) "a") = ("a", OpenQuote));;

assert ((next ("", OpenQuote) "\\") = ("", Quote));;
assert ((next ("", Quote) "x") = ("", HexQuote));;
assert ((next ("", HexQuote) "4") = ("", HexQuote_i "4"));;
assert ((next ("", HexQuote_i "4") "1") = ("A", OpenQuote));;

let unquote line =
        let cl = Str.(split (regexp_string "") line) in
        let result, token = List.fold_left next ("", Start) cl in
        result;;

assert (String.length (unquote "\"\"") = 0);;
assert (String.length (unquote "\"abc\"") = 3);;
assert (String.length (unquote "\"aaa\\\"aaa\"") = 7);;
assert (String.length (unquote "\"\\x27\"") = 1);;

let quote line =
        let cl = Str.(split (regexp_string "") line) in
        let next l r =
                match r with
                | "\"" -> l ^ "\\\""
                | "\\" -> l ^ "\\\\"
                | _    -> l ^ r in
        "\"" ^ (List.fold_left next "" cl) ^ "\"";;

assert ((quote "") = "\"\"");;
assert ((quote "abc") = "\"abc\"");;
assert ((quote "aaa\"aaa") = "\"aaa\\\"aaa\"");;
assert ((quote "\\x27") = "\"\\\\x27\"");; (* OMG WTF *)

let () =
        let rec loop length unquoted_length quoted_length =
                Printf.printf "%u - %u = %u\t" length unquoted_length (length - unquoted_length);
                Printf.printf "%u - %u = %u\n" quoted_length length (quoted_length - length);
                let line = read_line () in
                let unquoted_line = unquote line in
                let quoted_line = quote line in
                loop
                        (length + (String.length line))
                        (unquoted_length + (String.length unquoted_line))
                        (quoted_length + (String.length quoted_line)) in

        try
                loop 0 0 0
        with
                End_of_file -> ();;
