Testing a plugin README
=======================

The plugins project supports the process from a built plugin with a tarball
and an xml metadata file to a plugin available in the plugin installer.
This document introduces some tools and outlines the process.

The document assumes that there is a new plugin build available in
`/path/to/plugin`. Assuming the plugin is *oesenc_pi*, this means that
here is two files like  *oesenc-pi-1.2.0-3-flatpak-18.08.tar.gz* and
*oesenc-plugin-flatpak-18.08.xml*.

Examples assumes linux. Using other platforms is fine, but some paths will
be different.


Checking tarball layout
-----------------------

Unpack the tarball with something like `tar xf
/path/to/plugin/build/oesenc-pi-1.2.0-3-flatpak-18.08.tar.gz`. This will
create a new directory like *oesenc-pi-1.2.0-3-flatpak-18.08*. Check
that the directory tree layout matches the specs in the
[wiki](https://github.com/leamas/opencpn/wiki/Tarballs)


Local installation
------------------

The new tarball can be installed directly using the  _ocpn-install.sh_.
For example:

    $ tools/ocpn-install.sh \
         /path/to/plugin/build/oesenc-pi-1.2.0-3-flatpak-18.08.tar.gz

The installed tarball can be uninstalled using the plugin manager or
using _tools/ocpn-uninstall_.


Checking urls in the xml file
------------------------------

To be usable, the tarball needs to be uploaded to some location on the
web. The xml metadata file contains an url to this tarball location.

Check that all urls in the xml file are sane:

    $ tools/check-metadata-urls  \
         /path/to/plugin/build/oesenc-plugin-flatpak-18.08.xml


Create a new ocpn-plugins.xml
------------------------------

To create a new, modified ocpn-plugins.xml first create a private set
of xml source files,

    $ python tools/ocpn-metadata copy
    New xml sources copied to /home/al/.opencpn/plugins-metadata

Then copy the new xml file into this set:

    $ cp /path/to/plugin/build/oesenc-plugin-flatpak-18.08.xml \
          /home/al/.opencpn/plugins-metadata

and rebuild ocpn-plugins.xml:

    $ python ocpn-metadata generate
    Generated new ocpn-plugins.xml at /home/al/.opencpn/ocpn-plugins.xml


Check xml syntax:
-----------------

Check the generated file for syntax errors:

    $ xmllint --schema ocpn-plugins.xsd  ~/.opencpn/ocpn-plugins.xml --noout



Test the new catalog:
---------------------

Done like in _Create a new ocpn-plugins.xml_, the generated ocpn-plugins.xml
will be used when opencpn is started as long as the plugin catalog isn't updated.

The catalog can also be uploaded on the web and used as _Custom URL_ in the
plugin installer GUI.
