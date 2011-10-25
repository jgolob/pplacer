open Ppatteries
open Stree

type fig = int * IntSet.t

type t =
  | Dummy of int list
  | Figs of fig list

type fig_state = {
  max_bl: float option;
  edges: IntSet.t;
  rep_edge: int;
  accum: fig list;
}

type fold_state = {
  bls: float list;
  all_edges: IntSet.t;
  rep_opt: (int * int) option;
  maybe_figs: fig list;
  tot_accum: fig list;
}

let add_edge_to_figs i fl =
  List.map (IntSet.add i |> second) fl

let fold_figs fl =
  List.fold_left
    (fun accum (j, cur) ->
      let cur_card = IntSet.cardinal cur.edges in
      {bls = maybe_cons cur.max_bl accum.bls;
       all_edges = IntSet.union cur.edges accum.all_edges;
       rep_opt = (match accum.rep_opt with
         | Some (_, prev_card) as prev when prev_card >= cur_card -> prev
         | _ -> Some (j, cur_card));
       maybe_figs = (cur.rep_edge, cur.edges) :: accum.maybe_figs;
       tot_accum = List.append cur.accum accum.tot_accum})
    {bls = []; all_edges = IntSet.empty; maybe_figs = [];
     rep_opt = None; tot_accum = []}
    fl

let _figs_of_gtree cutoff gt =
  let get_bl = Gtree.get_bl gt
  and top = Gtree.top_id gt in
  let rec aux = function
    | Leaf i ->
      {max_bl = Some (get_bl i);
       edges = IntSet.singleton i;
       rep_edge = i;
       accum = []}
    | Node (i, subtrees) ->
      let {bls; all_edges = edges; rep_opt; maybe_figs; tot_accum} =
        List.map (top_id &&& aux) subtrees |> fold_figs
      in
      let accum = if i = top then tot_accum else add_edge_to_figs i tot_accum
      and rep_edge = Option.get rep_opt |> fst in
      match List.sort (flip compare) bls with
        | [] -> {max_bl = None; edges; rep_edge; accum}
        | _ when i = top ->
          {max_bl = None; edges; rep_edge; accum = List.append accum maybe_figs}
        | [bl] ->
          {max_bl = Some (bl +. get_bl i); edges; rep_edge; accum}
        | bl1 :: bl2 :: _ when bl1 +. bl2 <= cutoff ->
          {max_bl = Some (bl1 +. get_bl i); edges; rep_edge; accum}
        | _ ->
          {max_bl = None; edges = IntSet.empty; rep_edge;
           accum = add_edge_to_figs i maybe_figs |> List.append accum}
  in
  (Gtree.get_stree gt |> aux).accum

let figs_of_gtree cutoff gt =
  if cutoff = 0. then
    Dummy (Gtree.nonroot_node_ids gt)
  else
    Figs (_figs_of_gtree cutoff gt)

let uniquifier () =
  let yielded = ref IntSet.empty in
  fun s ->
    IntSet.diff s !yielded
    |> tap (fun _ -> yielded := IntSet.union s !yielded)

let _enum_by_score figl score =
  let uniquify = uniquifier () in
  List.map (first score) figl
    |> List.sort (comparing fst |> flip)
    |> List.enum
    |> Enum.map
        (fun (_, edges) ->
          uniquify edges
            |> IntSet.elements
            |> List.map (score &&& identity)
            |> List.sort (comparing fst |> flip)
            |> List.enum)
    |> Enum.flatten

let enum_by_score score = function
  | Dummy l ->
    List.map (score &&& identity) l
      |> List.sort (comparing fst |> flip)
      |> List.enum
  | Figs fl -> _enum_by_score fl score

let enum_all = function
  | Dummy l -> List.enum l
  | Figs fl ->
    let uniquify = uniquifier () in
    List.enum fl
      |> Enum.map (snd |- uniquify |- IntSet.enum)
      |> Enum.flatten

let length = function
  | Dummy _ -> 0
  | Figs fl -> List.length fl

let onto_decor_gtree dt = function
  | Dummy _ -> dt
  | Figs fl ->
    List.fold_left
      (fun dt (_, edges) ->
        let color = Decor.random_color () in
        Decor_gtree.color_clades_above ~color edges dt)
      dt
      fl
    |> Gtree.get_bark_map
    |> IntMap.filter (fun b -> b#get_decor |> List.length < 2)
    |> Gtree.set_bark_map dt

