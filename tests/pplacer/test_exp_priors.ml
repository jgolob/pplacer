open Ppatteries
open OUnit
open Test_util

open Convex

let suite = [
  "test_exp_prior_map" >:: begin fun () ->
    let prior_map = Test_util.placeruns_of_dir "simple"
      |> List.find (Placerun.get_name |- (=) "test1")
      |> Placerun.get_ref_tree
      |> Core.exp_prior_map
    in
    check_map_approx_equal
      (IntMap.enum prior_map)
      (List.enum [
        0, 1.;
        1, 4.5;
        2, 9.;
        3, 2.5;
        4, 0.5;
      ])
  end;

]
