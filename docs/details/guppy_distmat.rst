This subcommand provides distances calculated as the sum of branch
lengths between all pairs of edges in a reference tree. The format of
the output is a lower-triangular matrix of pairwise distances, in
which margins correspond to edge numbers. Each distance is prefixed by
either an S ("serial") or a P ("parallel"). Definition of these terms,
as well as the procedure for calculating the distance from an
arbitrary placement on the tree to any edge is as follows.

A placement on an edge looks like this::

   proximal
    |
    |   d_p
    |
    |---- x
    |
    |   d_d
    |
    |
   distal



d\ :sub:`p` is the distance from the placement `x` to the proximal side of the
edge, and d\ :sub:`d` the distance to the distal side.

If the distance from `x` to a leaf `y` is an S-distance Q, then the path
from `x` to `y` will go through the distal side of the edge and we will
need to add d\ :sub:`d` to Q to get the distance from `x` to `y`.  If the distance
from `x` to a leaf `y` is a P-distance Q, then the path from `x` to `y` will
go through the proximal side of the edge, and we will need to subtract
d\ :sub:`d` from Q to get the distance from `x` to `y`. In either case, we
always need to add the length of the pendant edge, which is the second
column.

To review, say the values of the two leftmost columns are a and b for
a given placement `x`, and that it is on an edge `i`.  We are interested
in the distance of `x` to a leaf `y`, which is on edge `j`.  We look at the
distance matrix, entry (`i`, `j`), and say it is an S-distance Q. Then our
distance is Q+a+b.  If it is a P-distance Q, then the distance is
Q-a+b.

The distances between leaves should always be P-distances, and there
we need no trickery.
