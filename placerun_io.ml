(* pplacer v0.3. Copyright (C) 2009  Frederick A Matsen.
 * This file is part of pplacer. pplacer is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. pplacer is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details. You should have received a copy of the GNU General Public License along with pplacer. If not, see <http://www.gnu.org/licenses/>.
 *)

open Fam_batteries
open MapsSets

let version_str = "v1.0"
let compatible_versions = [ "v0.3"; "v1.0"; ]

let bifurcation_warning = 
  "Warning: pplacer results make the most sense when the \
  given tree is multifurcating at the root. See manual for details."

let chop_place_extension fname =
  if Filename.check_suffix fname ".place" then
    Filename.chop_extension fname
  else 
    invalid_arg ("this program requires place files ending with .place suffix, unlike "^fname)

 
(* ***** WRITING ***** *)

let write_unplaced ch unplaced_list = 
  if unplaced_list <> [] then
    Printf.fprintf ch "# unplaced sequences\n";
  List.iter (Pquery_io.write ch) unplaced_list

let write_placed_map ch placed_map = 
  IntMap.iter
    (fun loc npcl ->
      Printf.fprintf ch "# location %d\n" loc;
      List.iter (Pquery_io.write ch) npcl)
    placed_map

let write_by_best_loc criterion ch placerun =
  let (unplaced_l, placed_map) = 
    Placerun.make_map_by_best_loc criterion placerun in
  write_unplaced ch unplaced_l;
  write_placed_map ch placed_map

let to_file invocation placerun = 
  Placerun.warn_about_duplicate_names placerun;
  let ch = open_out ((Placerun.get_name placerun)^".place") in
  let ref_tree = Placerun.get_ref_tree placerun in
  Printf.fprintf ch "# pplacer %s run, %s\n"        
    version_str (Base.date_time_str ());
  Printf.fprintf ch "# invocation: %s\n" invocation;
  Prefs.write ch (Placerun.get_prefs placerun);
  Printf.fprintf ch "# output format: location, ML weight ratio, PP, ML likelihood, marginal likelihood, attachment location (distal length), pendant branch length\n";
  if not (Stree.multifurcating_at_root (Gtree.get_stree ref_tree)) then
    Printf.fprintf ch "# %s\n" bifurcation_warning;
  (* we do the following to write a tree with the node numbers in place of
   * the bootstrap values, and at @ at the end of the taxon names *)
  Printf.fprintf ch "# numbered reference tree: %s\n" 
    (Newick.to_string (Newick.to_numbered ref_tree));
  Printf.fprintf ch "# reference tree: %s\n" (Newick.to_string ref_tree);
  write_by_best_loc 
    Placement.ml_ratio 
    ch 
    placerun;
  close_out ch


(* ***** READING ***** *)

(* returns a placerun
 * conventions for placement files: 
  * first line is 
# pplacer [version] run ...
  * then whatever. last line before placements is
# reference tree: [ref tre]
*)
let of_file place_fname = 
  let reftree_rex = Str.regexp "^# reference tree: \\(.*\\)"
  and invocation_rex = Str.regexp "^# invocation:"
  and fastaname_rex = Str.regexp "^>"
  and str_match rex str = Str.string_match rex str 0
  and name = chop_place_extension (Filename.basename place_fname)
  in
  match 
  (* split up the file by the fastanames *)
    File_parsing.partition_list 
      (str_match fastaname_rex) 
      (File_parsing.string_list_of_file place_fname) 
  with
  | [] -> failwith (place_fname^" empty place file!")
  | header::placements -> 
  (* parse the header, getting a ref tree *)
  let (prefs, ref_tree) = 
    try 
      match header with
      | [] -> failwith (place_fname^" no header!")
      | version_line::header_tl -> begin
      (* make sure we have appropriate versions *)
      Scanf.sscanf version_line "# pplacer %s run" 
        (fun file_vers ->
          if not (List.mem file_vers compatible_versions) then
            failwith
              (Printf.sprintf 
               "This file is from version %s which is incompatible with the present version of %s"
               file_vers
               version_str));
      let _, post_invocation = 
        File_parsing.find_beginning 
          (str_match invocation_rex) 
          header_tl in
      let prefs = Prefs.read post_invocation in
      (* get the ref tree *)
      let tree_line,_ = 
        File_parsing.find_beginning 
          (str_match reftree_rex) 
          post_invocation 
      in
      (prefs,
        Newick.of_string (Str.matched_group 1 tree_line))
      end
    with
    | Scanf.Scan_failure s ->
      failwith ("problem with the place file: "^s)
    | Not_found -> failwith "couldn't find ref tree line!"
  in
  Placerun.make
    ref_tree
    prefs
    name
    (List.map 
      (fun pquery_lines ->
        Pquery_io.parse_pquery 
          (File_parsing.filter_comments pquery_lines))
      placements)
