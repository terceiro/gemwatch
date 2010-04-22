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
