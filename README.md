OpenCPN plugins project README
===============================

This project is currently in an utterly experimental state. It is
aimed to be an important groundwork for the proposed plugin installer [1].

The project exports the fundamental pieces required to install a plugin using
the new installer: The plugin catalogue `ocpn-plugins.xml` and the plugin
icons in the `icons/` directory.

Dependencies
------------

  - python >= 3.4


Fast track: creating a modified ocpn-plugins.xml
------------------------------------------------

To create a  modified ocpn-plugins.xml drop new or modified xml files in the
metadata directory. Then do


     python tools/ocpn-metadata generate --userdir metadata --destfile ocpn-plugins.xml

This will create ocpn-plugins.xml in current directory. As an alternative, use


     python tools/ocpn-metadata generate --userdir metadata

which installs the xml file in the user data directory where it will override 
whatever file opencpn was installed with. You might want to add
```--version``` to mark the generated file with a new version.

Developer info
--------------

Notes on the XML files, tarball layout and platform issues: DEVELOPER-INFO.md.
Here is also mer elaborated instructions to create ocpn-plugins.xml if the
fast track fails.


[1] https://github.com/OpenCPN/OpenCPN/pull/1457
