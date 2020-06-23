#!/bin/bash

if [ -z $CI ] && [ -z $GITHUB_ACTION ]; then
    if [ "$#" -ne "2" ]; then
        echo "Incorrect invocation: Should be validate_xml.sh plugin_name plugin_version"
        echo "where:"
        echo "   plugin_name is the name of the plugin, i.e. testplugin_pi"
        echo "   plugin_version is the version number, i.e. 1.0.114.0"
        echo ""
        echo "   Full command should look like:"
        echo "      validate_xml.sh testplugin_pi 1.0.114.0"
        exit
    fi
    exit_rc=0
    for file in metadata/$1-$2*.xml
    do
        `xmllint  --schema ocpn-plugins.xsd $file --noout 2> /dev/null`
        rc=$?
        if [ $rc -gt 0 ]; then
            `xmllint  --schema ocpn-plugins.xsd $file --noout`
            exit_rc=$rc
        fi
    done
    if [[ $exit_rc == 0 ]]; then
        echo "All files pass xsd check"
    fi
    exit $exit_rc
else
    exit_rc=0
    URL="https://api.github.com/repos/${GITHUB_REPOSITORY}/pulls/${REQUEST_NO}/files"
    FILES_FOUND=$(curl -s -X GET -G $URL | jq -r '.[] | .filename')
    files_array=($FILES_FOUND)
    for file in "${files_array[@]}"
    do
        if [[ $file == "metadata"*".xml" ]]; then
            echo "Processing file: $file"
            `xmllint  --schema ocpn-plugins.xsd $file --noout 2> /dev/null`
            rc=$?
            if [ $rc -gt 0 ]; then
                `xmllint  --schema ocpn-plugins.xsd $file --noout`
                exit_rc=$rc
            fi
        fi
    done

    if [[ $exit_rc == 0 ]]; then
        echo "All files pass git pull xsd check"
    fi
    exit $exit_rc
fi
