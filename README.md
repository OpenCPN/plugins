OpenCPN plugins project README
===============================

This project is currently in a experimental state. It is an important
groundwork for the new plugin installer.

The project exports the fundamental piece required to install plugins using
the new installer: the plugin catalog `ocpn-plugins.xml`


Dependencies
------------

  - python >= 3.6    (for print f)
  - GNU make (optional)
  - tar
  - xmllint, sometimes found in the libxml, libxml2  or xsltproc package

On Windows, first install chocolatey as described on https://chocolatey.org.
Then install the dependencies python,  make,  git  and xsltproc using
`choco install git` etc.

On macos, packages are available in homebrew. Linux distros normally have these
available by default.

ocpn-metadata, the most important tool, only depends on python.


Fast track: creating a modified ocpn-plugins.xml
------------------------------------------------

Drop new or modified xml files in the metadata/ directory. Then do

    > python tools/ocpn-metadata generate --userdir metadata \
          --destfile ocpn-plugins.xml

This will create ocpn-plugins.xml in current directory. You might want to add
```--version``` to mark the generated file with a new version.


Fast track: Checking URL's used in ocpn-plugins.xml
------------------------------------------------

    > python tools/ocpn-metadata-urls [path]  path assumed is to ocpn-plugins.xml
	

Fast track: Batch Files to use the above commands
------------------------------------------------

    > check.bat   - to be run from the "plugins" directory

    > runcheck.bat   - to be run from the "tools" directory


Developer info
--------------

The developer workflow includes generating new plugins, checking tarball
xml data, testing  and creating a new ocpn-plugins.xml. This is described
in TESTING.md.


[1] https://github.com/OpenCPN/OpenCPN/pull/1457
