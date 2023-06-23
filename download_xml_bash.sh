#!/bin/bash

if [ "$#" -ne "4" ]; then
	echo "Incorrect invocation: Should be download_xml_bash.sh cloudsmith_repository plugin_version cloudsmith_user cloudsmith_level"
	echo "where:"
	echo "   cloudsmith_repository is the name of the repository on cloudsmith the files are in, i.e. testplugin"
	echo "   plugin_version is the version number, i.e. 1.0.114.0"
	echo "   cloudsmith_user is the user name associated with the cloudsmith repository, i.e. jon-gough or opencpn"
	echo "   cloudsmith_level is the level of the repository and is one of: prod, beta, alpha"
	echo ""
	echo "   Full command should look like:"
	echo "      download_xml_bash.sh testplugin_pi 1.0.114.0 jon-gough prod"
	echo "      download_xml_bash.sh weather-routing 1.13.8.0 opencpn prod"
	exit
fi

NAME="$1"
VERSION="$2"
USER="$3"
LEVEL="$4"

REPO="https://cloudsmith.io/~${USER}/repos/"
echo "Issuing command: wget -q -O - $REPO${NAME}-${LEVEL}/packages/?q=*${VERSION}*.xml"
my_array=()
echo "Show current files that match criteria"
ls metadata/${NAME}*-*${VERSION}*xml -la
echo "Deleting current files that match criteria"
rm metadata/${NAME}*-*${VERSION}*xml
echo "Finding files on remote cloudsmith repository"
delimiter="href=\""
delimiter1=".xml\" title"
my_array=();
while read -r line; do
	if [[ $line == *$delimiter* ]] && [[ $line == *$delimiter1* ]]; then
		start=`awk -v a="$line" -v b="$delimiter" 'BEGIN{print index(a,b)}'`
		start=$((start + ${#delimiter} - 1))
		end=`awk -v a="$line" -v b="$delimiter1" 'BEGIN{print index(a,b)}'`
		end=$((end + 3 - start))
		line=${line:$start:$end}
		my_array+=( $line );
		echo "found: $line"
	fi
done < <(wget -q -O - "$REPO${NAME}-${LEVEL}/packages/?q=*${VERSION}*xml+tag:latest&page_size=50")

echo "Downloading files found that match criteria"
for URL in "${my_array[@]}"
do
  echo "URL: $URL"
  wget --progress=bar:force:noscroll -c $URL -P metadata
done
echo "Files downloaded"
ls -la metadata/${NAME}*-*${VERSION}*xml

