By default, ``guppy fpd`` outputs a matrix containing in each row: the
placefile name, the phylogenetic entropy (``phylo_entropy``, `Allen 2009`_),
the quadratic entropy (``quadratic``, `Rao 1982`_, `Warwick and Clark 1995`_)
phylogenetic diversity (``unrooted_pd``, `Faith 1992`_), phylogenetic diversity
which only requires distal mass (``rooted_pd``, this is as oppposed to ``pd``
requiring both distal and proximal mass), and a new diversity metric
generalizing PD to incorporate abundance: balance-weighted phylogenetic
diversity (``bwpd``).

When passed a ``--theta`` flag and a comma-delimited list of values for
``theta``, a one-parameter family of functions is used to calculate a diversity
measure that scales the incorporation of abundance from traditional
phylogenetic diversity (at theta = 0.0) to abundance-weighted phylogenetic
diversity (at theta = 1.0). A column labeled ``bwpd_[theta]`` is added to the
output for each.

When passed a ``--chao-d`` flag and a comma-delimited list of values for ``q``,
the ``qD(T)`` measure of `Chao 2010`_ is added to the output for each value of
``q``.

.. _`Chao 2010`: http://dx.doi.org/10.1098/rstb.2010.0272
.. _`Rao 1982`: http://dx.doi.org/10.1016/0040-5809(82)90004-1
.. _`Faith 1992`: http://dx.doi.org/10.1016/0006-3207(92)91201-3
.. _`Warwick and Clark 1995`: http://dx.doi.org/10.3354/meps129301
.. _`Allen 2009`: http://dx.doi.org/10.1086/600101

