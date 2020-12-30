#!/bin/bash

set -euo pipefail

# Determine the correct version, this is derived
# from the latest commit to the 'ci' branch in the code
# project, which is next door (../radar-pi)

if [ $# != 4 ]
then
  echo "Usage: $0 <project> <cloudsmith-user> <cloudsmith-repo> <tag/commit>"
  echo ""
  exit 2
fi

PROJECT="${1}"
CLOUDSMITH_USER="${2}"
CLOUDSMITH_REPO="${3}"
QUERY="${4}"
TOPDIR="${PWD}"

cd metadata
for url in $(
curl -s -S "https://api.cloudsmith.io/packages/${CLOUDSMITH_USER}/${CLOUDSMITH_REPO}/?page_size=9999&query=${QUERY}" |
  jq -r '.[] |
         select(.extension == ".xml") |
         .cdn_url'
)
do
  echo $url
  # -r to clobber existing file
  file=$(basename "${url}")
  curl -s -S -o "${file}" "${url}"
  xmllint --schema "${TOPDIR}/ocpn-plugins.xsd" "${file}"
done
