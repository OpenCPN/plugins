OpenCPN plugins project README
===============================

This project is the underpinnings for the new plugin installer. It exports
the fundamental piece required to install plugins using the installer:
the plugin catalog `ocpn-plugins.xml`

Doing so, the project also defines the formal interface for plugin
developers who wants their plugins to be included in the catalog.

The project also provides some tools and workflows to create and verify
a new version of the catalog. These are by no means mandatory, but seems
to be useful for many plugin developers.

Formal interface
----------------

New plugins (really new or updates) are accepted into the catalog after
issuing a pull request (PR) against this project, a PR which updates
files in the metadata directory.

The PR could be accepted into one of three branches:

  - master, used by regular users.
  - Beta, for reasonably stable test plugins.
  - Alpha, for experimental plugins.


Tools and workflows
-------------------

### Dependencies

  - python >= 3.6
  - GNU make (optional)
  - tar
  - xmllint, sometimes found in the libxml, libxml2 or xsltproc package

On Windows, first install chocolatey as described on https://chocolatey.org.
Then install the dependencies python, make, git and xsltproc using
`choco install git` etc.

On macos, packages are available in homebrew. Linux distros normally have these
available by default.

ocpn-metadata, the most important tool, only depends on python.

### Git pre-commit hook

After having dependencies installed users are strongly recommended to
install the `pre-commit` file into `.git/hooks`. This will run a test
on all files committed. If the test produces false negatives the
`--no-verify` option can be used to commit even if the hook cannot complete
successfully. Running the tests locally avoids broken committs from the very
beginning, avoiding all sorts of troubles.


### Windows tools

Windows users have two support scripts which checks the urls:

    > check.bat   - to be run from the "plugins" directory

    > runcheck.bat   - to be run from the "tools" directory


### Checking all XML files for validity against XSD

Check that all files about to be pushed to upstream repository (main
repository) will pass validation checks

	$ ./validate_xml.sh plugin_name plugin_version

i.e.
        ./validate_xml.sh testplugin_pi 1.0.120.0

This will show all good xml files and identify any that do not meet the
XSD. If in doubt make sure you have the latest version of the plugins master,
Alpha, Beta or Experimental branch that you are working with. Occasionally
there are changes to the XSD. The same script will be run when you generate
a Pull request and if the Pull fails this test it will not be merged.


### The frontend2 workflow

Many plugins currently uses the frontend2 workflow. It is based on plugins
uploading metadata for each build to cloudsmith repositories. The workflow
downloads these plugins and creates a git pull request based on the update.

The basic tool is the 'download_xml_bash.sh' script. This script will run
on Linux and also on Windows using the 'git bash' environment.
	
	> ./download_xml_bash.sh cloudsmith_repository \
                plugin_version cloudsmith_user cloudsmith_level
e. g.,

	./download_xml_bash.sh testplugin_pi 1.0.114.0 jon-gough prod
	./download_xml_bash.sh weather-routing 1.13.8.0 opencpn prod

These files can then be added to the push request in git.

With the new process do NOT generate the ocpn-plugins.xml file as this will be
done automatically when the push is merged into the mainline.


Developer info
--------------

The developer workflow includes expanded info on generating new plugins,
checking tarball xml data, testing and creating a new ocpn-plugins.xml.
This is described in TESTING.md.
