#!/bin/bash

function usage() {
cat << EOT
Usage: validate_xml.sh [plugin_name version]

Parameters:
    plugin_name:
        Name of plugin, for example testplugin_pi
    version:
        Complete version like 1.0.114.0

If invoked with plugin_name and version: validate all matching metadata
using the .xsd file. Otherwise default to check the diff against
upstream at https://github.com/OpenCPN/plugins using the same branch.

Examples:
    validate_xml.sh testplugin_pi 1.0.114.0
    validate_xml.sh
EOT
}

exit_rc=0
if [ $# -eq 2 ]; then
    for file in metadata/$1-$2*.xml; do
        xmllint --schema ocpn-plugins.xsd $file --noout || exit_rc=1
    done
elif [ $# -eq 0 ];  then
    git remote add upstream https://github.com/OpenCPN/plugins.git
    branch=$(git branch --show-current)
    if ! git ls-remote --exit-code --heads upstream $branch; then
        echo "Branch $branch can not be found on upstream, no checks done"
        exit 0;
    fi
    git fetch upstream $branch
    for f in $(git diff --name-only --diff-filter=ACMR upstream/$branch HEAD)
    do
        if [[ $file == metadata*.xml ]]; then
            echo "Processing file: $file"
            xmllint --schema ocpn-plugins.xsd $file --noout || exit_rc=1
        fi
    done
else
    usage; exit 0
fi
if [[ $exit_rc == 0 ]]; then
    echo "All files pass xsd check"
fi
exit $exit_rc
