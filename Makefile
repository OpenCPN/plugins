#
#  Makefile to create ocpn-plugins.xml. 
#
#  Needs python >= 3.4 available as the command python. Should
#  otherwise work on all platforms but only tested on Linux.


all: ocpn-plugins.xml


ocpn-plugins.xml: metadata/*.xml
	tools/ocpn-metadata generate --force --destfile $@ --userdir metadata
