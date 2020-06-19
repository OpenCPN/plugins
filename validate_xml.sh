#!/bin/bash

#if [ "$#" -ne "2" ]; then
#	echo "Incorrect invocation: Should be validate_xml.sh plugin_name plugin_version"
#	echo "where:"
#	echo "   plugin_name is the name of the plugin, i.e. testplugin_pi"
#	echo "   plugin_version is the version number, i.e. 1.0.114.0"
#	echo ""
#	echo "   Full command should look like:"
#	echo "      validate_xml.sh testplugin_pi 1.0.114.0"
#	exit
#fi

#for file in metadata/$1-$2*.xml
#for file in metadata/*.xml
#do
#	`xmllint  --schema ocpn-plugins.xsd $file --noout 2> /dev/null`
#	rc=$?
#	if [ $rc -gt 0 ]; then
#		`xmllint  --schema ocpn-plugins.xsd $file --noout`
#		exit_rc=$rc
#	fi
#done
git show --name-only --oneline HEAD
while read -r file; do
    if [[ $file == *".xml" ]]; then
        `xmllint  --schema ocpn-plugins.xsd $file --noout 2> /dev/null`
        rc=$?
        if [ $rc -gt 0 ]; then
            `xmllint  --schema ocpn-plugins.xsd $file --noout`
            exit_rc=$rc
        fi
	fi
done < <( git show --name-only --oneline HEAD)
exit $exit_rc
