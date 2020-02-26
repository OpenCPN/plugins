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
  - GNU make (optional)


Fast track: creating a modified ocpn-plugins.xml
------------------------------------------------

Windows users need to fix the deps. First install chocolatey as described
at https: //chocolatey.org. Then install the deps:

    > choco install python
    > choco install make
    > choco install git

Drop new or modified xml files in the metadata/ directory. Then do

    > python tools/ocpn-metadata generate --userdir metadata --destfile ocpn-plugins.xml

This will create ocpn-plugins.xml in current directory. As an alternative, use

    > python tools/ocpn-metadata generate --userdir metadata

which installs the xml file in the user data directory where it will override 
whatever file opencpn was installed with. You might want to add
```--version``` to mark the generated file with a new version.

A third option is to just use `make` which creates a ocpn-plugins.xml in 
current directory.


Developer info
--------------

Notes on the XML files, tarball layout and platform issues: DEVELOPER-INFO.md.
Here is also mer elaborated instructions to create ocpn-plugins.xml if the
fast track fails.

The pre-commit file is a git hook which validates ocpn-plugins.xml when
committed. See more info in this file.


[1] https://github.com/OpenCPN/OpenCPN/pull/1457
