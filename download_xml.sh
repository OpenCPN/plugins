#!/bin/bash

if [ "$#" -ne "4" ]; then
	echo "Incorrect invocation: Should be download_xml.sh plugin_name plugin_version cloudsmith_user cloudsmith_level"
	echo "where:"
	echo "   plugin_name is the name of the plugin, i.e. testplugin_pi"
	echo "   plugin_version is the version number, i.e. 1.0.114.0"
	echo "   cloudsmith_user is the user name associated with the cloudsmith repository, i.e. jon-gough"
	echo "   cloudsmith_level is the level of the repository and is one of: prod, beta, alpha"
	echo ""
	echo "   Full command should look like:"
	echo "      download_xml.sh testplugin_pi 1.0.114.0 jon-gough alpha"
	exit
fi

REPO="https://cloudsmith.io/~$3/repos/"
echo "Issuing command: lynx -dump $REPO$1-$4/packages/?q=*$2*.xml |  awk {'print $2'} |grep '.xml$' |grep $1-$2"
my_array=()
echo "Show current files that match criteria"
ls metadata/$1-$2*xml -la
echo "Deleting current files that match criteria"
rm metadata/$1-$2*xml
echo "Finding files on remote cloudsmith repository"
while IFS= read -r line; do
    my_array+=( "$line" )
done < <( lynx -dump $REPO$1-$4/packages/?q=*$2*.xml |  awk {'print $2'} |grep '.xml$' |grep $1-$2 )

echo "Downloading files found that match criteria"
for URL in "${my_array[@]}"
do
  echo $URL
  wget --progress=bar:force:noscroll -c $URL -P metadata
done
echo "Files downloaded"
ls metadata/$1-$2*xml -la

