Creates and populates tables in the specified sqlite3 database, initializing
the database if it doesn't already exist.

The following tables are both created and populated with data from the
reference pacakge:

* ``ranks`` -- all of the ranks contained in the provided reference package.
* ``taxa`` -- all of the taxa in the provided reference package.

Other tables are created, but are populated by :ref:`guppy classify
<guppy_classify>`.

See the `microbiome demo`_ for some examples of using ``rppr prep_db`` and
``guppy classify`` together.

.. _microbiome demo: http://fhcrc.github.com/microbiome-demo/
