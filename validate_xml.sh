#!/bin/bash

function usage() {
cat << EOT
Usage:  validate_xml.sh <plugin_name> <version>

Parameters:
    plugin_name:
        Name of plugin, for example testplugin_pi
    version:
        Complete version like 1.0.114.0

Example:
    validate_xml.sh testplugin_pi 1.0.114.0
EOT
}

exit_rc=0
if [ -z $CI ] && [ -z $GITHUB_ACTION ]; then
    if [ "$#" -ne "2" ]; then usage; exit 0; fi

    for file in metadata/$1-$2*.xml
    do
        if ! xmllint --schema ocpn-plugins.xsd $file --noout 2>/dev/null
        then
            xmllint --schema ocpn-plugins.xsd $file --noout
            exit_rc=1
        fi
    done
else
    URL="https://api.github.com/repos/${GITHUB_REPOSITORY}/pulls/${REQUEST_NO}/files"
    FILES_FOUND=$(curl -s -X GET -G $URL | \
                  jq -r 'map(select(.status != "removed")) | .[] | .filename')
    files_array=($FILES_FOUND)
    for file in "${files_array[@]}"
    do
        if [[ $file == metadata*.xml ]]; then
            echo "Processing file: $file"
            if ! xmllint  --schema ocpn-plugins.xsd $file --noout 2> /dev/null
            then
                xmllint  --schema ocpn-plugins.xsd $file --noout
                exit_rc=1
            fi
        fi
    done
fi
if [[ $exit_rc == 0 ]]; then
    echo "All files pass xsd check"
fi
exit $exit_rc
