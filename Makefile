#
#  Makefile to create ocpn-plugins.xml. 
#
#  Needs python >= 3.4 available as the command python. Should
#  otherwise work on all platforms but only tested on Linux.
#
#  The validate target requires xmllint found in packages like
#  xsltproc or libxslt


all: ocpn-plugins.xml

VERSION  ?= 0.0.1


ocpn-plugins.xml: metadata/*.xml Makefile
	python3 tools/ocpn-metadata generate --force --destfile $@ \
	    --userdir metadata --version $(VERSION)

clean:
	rm -f ocpn-plugins.xml

validate: ocpn-plugins.xml Makefile
	xmllint  --schema ocpn-plugins.xsd  ocpn-plugins.xml --noout

check-urls:
	tools/check-metadata-urls ocpn-plugins.xml
