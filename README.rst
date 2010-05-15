gemwatch - Watch rubygems.org and download gems converted to tarballs
=====================================================================

Introduction
------------

This application was designed to help Debian developers in tracking Ruby
software released only as rubygems.

Usage in Debian watch files
---------------------------

Debian package maintainers can use the following syntax in their watch files to
be properly warned of new upstream releases::

  version=3
  http://gemwatch.heroku.com/${gem} /download/${gem}-(.*)\.tar\.gz

Gem conversion to tarball
-------------------------

A gem named ``mygem-0.1.0.gem`` is converted in a tarball with the following
steps::

  mkdir mygem-0.1.0
  cd mygem-0.1.0
  wget ...../mygem-0.1.0.gem
  tar xf mygem-0.1.0.gem
  tar xzf data.tar.gz
  xcat metadata.gz > metadata.yml
  rm -f mygem-0.1.0.gem data.tar.gz metadata.gz
  cd ..
  tar czf mygem-0.1.0.tar.gz mygem-0.1.0

This way:

* The tarball contains all the files the gem contains
* The gem metadata ends up in a file named ``metadata.yml`` inside the tarball

Running as CGI
--------------

* Create a symlink pointing to the ``cgi`` script into your ``cgi-bin`` directory. The symlink can be named as you wish.
* Make sure gemwatch's ``public`` directory is accessible as ``/gemwatch``
* Example:
** ``http://mysite.com/cgi-bin/gemwatch``, where ``gemwatch`` is a symlink to gemwatch's ``cgi`` script
** ``http://mysite.com/gemwatch`` is a symlink (or an alias) to gemwatch's ``public`` directory.

License
-------

Copyright © 2010, Antonio Terceiro <terceiro@softwarelivre.org>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
