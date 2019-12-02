OpenCPN plugins project developer info
======================================

This project is currently in an utterly experimental state. It is
aimed to be an important groundwork for the proposed plugin installer [1].

The project exports the fundamental pieces required to install a plugin using
the new installer: The plugin catalog `ocpn-plugins.xml` and the plugin
icons in the `icons/` directory.

`ocpn-plugin.xml` is basically built by merging the files in the `metadata/`
using the tool ocpn-metadata. Each file in  the metadata directory represents
a plugin build for a given platform. The shorthand command is *make*.

The subdirectores metadata and icons provides support for plugins
which can be downloaded and installed by the new plugin UI. Note
that the previous way to install using installation packages is
still supported.

See the wiki at https://github.com/leamas/opencpn/wiki for more
info on the installer

ocpn-plugins.xml
----------------

The file ocpn-plugins.xml represents the plugin catalog available for
users to install. This file is created by merging a set of separate
xml files. The catalog could be re-generated from sources.

Creating a new xml file should be straight-forward using existing
examples. Patching existing xml files is of course also possible.
BEWARE: The name is as returned by the `common_name` function,
typically without the *_pi* suffix.

The process to regenerate the catalog starts on Windows by installing 
chocolatey as describe on https://chocolatey.org

Then install the dependencies:

   choco install python make git

MacOS users needs to ensure that python >= 3.4 is installed and available
as the command `python`.
 
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
distributed one (see [wiki]). ocpn-metadata has command line
options to tweak the locations used, see `ocpn-metadata --help`


[wiki] wiki :https://github.com/leamas/opencpn/wiki
