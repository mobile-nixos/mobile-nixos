*Documentation internal notes*
==============================

This document is not to be generated into the website/documentation.

* * *

Implementation notes
--------------------

This documentation folder generates the Mobile NixOS website *and* documentation
as a whole.

The documentation is to be written in asciidoc, and converted through a custom
pipeline through the Asciidoctor API. Markdown files are accepted in the
pipeline, but frowned upon except for the simplest documentation articles.

The build pipeline can be improved upon, and contributions doing so are welcome!


Devices list
------------

The `devices` folder is special and assumes it will be replaced in-place with
asciidoc source files generated from a build outside of the main documentation
build. This is because it is generated from the actual device descriptions from
the repository.


Sitemap
-------

The sitemap is simply a dump of all document files and "catalogs" from as parsed
by Asciidoctor.

