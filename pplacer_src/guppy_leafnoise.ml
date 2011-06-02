open MapsSets
open Subcommand
open Guppy_cmdobjs

class cmd () =
object (self)
  inherit subcommand () as super
  inherit rng_cmd () as super_rng
  inherit refpkg_cmd ~required:true as super_refpkg

  val n_locations = flag "-l"
    (Needs_argument ("n_locations", "The number of random locations to select."))
  val n_pqueries = flag "-q"
    (Needs_argument ("n_pqueries", "The number of placements to put in each placefile."))

  method specl =
    super_refpkg#specl
  @ super_rng#specl
  @ [
    int_flag n_pqueries;
    int_flag n_locations;
  ]

  method desc = "generate placefiles uniformly on leaves"
  method usage = "usage: leafnoise [options] -c my.refpkg"

  method action namel =
    List.iter
      (fun name ->
        let rt = Refpkg.get_ref_tree self#get_rp in
        Commiesim.write_clustered_random_pr
          self#rng
          rt
          (Gtree.leaf_ids rt)
          name
          ~n_locations:(fv n_locations)
          ~n_pqueries:(fv n_pqueries))
      namel
end