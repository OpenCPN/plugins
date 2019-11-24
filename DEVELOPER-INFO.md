OpenCPN plugins project README
===============================

This project is currently in an utterly experimental state. It is
aimed to be an important groundwork for the proposed plugin installer [1].

The project exports the fundamental pieces required to install a plugin using
the new installer: The plugin catalogue `ocpn-plugins.xml` and the plugin
icons in the `icons/` directory.

`ocpn-plugin.xml` is basically built by merging the files in the `metadata/`
using the tool ocpn-metadata. Each file in  the metadata directory represents
a plugin build for a given platform. The shorthand command is *make* on linux
and macos, *make\_catalogue.bat* on windows

The subdirectores metadata and icons provides support for plugins
which can be downloaded and installed by the new plugin UI. Note
that the previous way to install using installation packages is
still supported.

Plugins which could be downloaded and installed needs to have:

  - A downloadable installation tarball available at an URI.
  - Plugin metadata merged into the common file ocpn-plugins.xml.
  - An optional icon available in the plugins/icons directory.


Tarball
-------

The installable plugin tarball is basically the result of *make install*
packed into a tar archive. Directory layout is platform-dependent,
see below.


ocpn-plugins.xml
----------------
The file ocpn-plugins.xml represents the plugin catalogue available for
users to install. This file is created by merging a set of separate
xml files. The catalogue could be re-generated from sources.

Creating a new xml file should be straight-forward using existing
examples. Patching existing xml files is of course also possible.
BEWARE: The name is as returned by the `common_name` function,
typically without the *_pi* suffix.

The process to regenerate the catalogue starts on Windows by adding the
OpenCPN install directory to %PATH%, like:

   C:> set PATH=%PATH%;C:\Program Files (x86)\OpenCPN

Windows and MacOS users also needs to ensure that python >= 3.4 is
installed and available as the command `python`.
 
The procedure is then done on the command line using the *ocpn-metadata*
tool. This works in two steps. The first is to create a private set of
xml source files, something like:

    $  python ocpn-metadata copy
    New xml sources copied to /home/al/.opencpn/plugins-metadata 

Now is the time to patch or add new xml files in
*/home/al/.opencpn/plugins-metadata*. When done, generate the new 
ocpn-plugins.xml using:

    $  python ocpn-metadata generate
    Generated new ocpn-plugins.xml at /home/al/.opencpn/ocpn-plugins.xml

The generated file is by default placed in a location overriding the
distributed one (see Platform Notes below). ocpn-metadata has command line
options to tweak the locations used, see `ocpn-metadata --help`

Icons
-----

The plugin downloader supports png and svg icons.The basename of
the icon should be the same as the name in the xml metadata.

Icons are rescaled when displayed. For this reason svg icons are
preferred. Png icons should be reasonable large e. g. 64 x 64.


Platform notes - linux.
-----------------------

System-wide metadata: Typically  */usr/share/opencpn/ocpn-plugins.xml*,
possibly  distribution-dependent.

User metadata (overrides system if existing): *~/.opencpn/ocpn-plugins.xml*

Tarball layout (top directory could have any name):

   - .so dynamic libraries goes into *top-dir/usr/lib/opencpn* or
     *top_dir/usr/local/lib/opencpn*.

   - Optional helper binaries goes into *top-dir/usr/bin* or
     *top-dir/usr/local/bin*.

   - Plugin data files: *top-dir/usr/share/opencpn/plugins/<name>*
     where <name> is as in the plugin metadata.


Platform notes - Windows
------------------------

System-wide metadata: *C:\Program Files (x86)\OpenCPN\ocpn-plugins.xml*

User metadata (overrides system if existing):
    *:C:\ProgramData\opencpn\ocpn-plugins.xml*

Tarball layout (top directory could have any name):

   - .dll dynamic libraries and .exe binaries goes to
     *top-dir/plugins/\*.exe*
   - plugin data files goes to *top-dir/plugins/plugin-name*


Platform notes - MacOS
----------------------

System-wide metadata:
    *~/Desktop/OpenCPN.app/Contents/SharedSupport/ocpn-plugins.xml*

User metadata (overrides system if existing):
    *~/Library/Preferences/opencpn/ocpn-plugins.xml*

Tarball layout (top directory could have any name):

  - dylib dynamic libraries and binaries:
    *top-dir/OpenCPN.app/Contents/PlugIns/*

  - Data files:
    *top-dir/OpenCPN.app/Contents/SharedSupport/plugins/plugin-name*

NOTE: A deprecated prefix *topdir/tmp/bin* is still supported.


Platform notes - Flatpak
------------------------

System-wide metadata: */app/share/opencpn/ocpn-plugins.xml*

User metadata (overrides system if existing): *~/.opencpn/ocpn-plugins.xml*

Tarball layout: 

   - .so dynamic libraries goes into *top-dir/lib/opencpn*

   - Optional helper binaries goes into *top-dir/bin* 

   - Plugin data files: *top-dir/share/opencpn/plugins/<name>*
     where <name> is as in the plugin metadata.

   - metadata.json is at top level.



