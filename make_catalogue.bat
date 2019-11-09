#
# Windows batch file, creates ocpn-plugins.xml
#
# Needs python >= 3.4 available as the command 'python'.

tools/ocpn-metadata generate --force --destfile ocpn-plugins.xml --userdir metadata
