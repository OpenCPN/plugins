#!/bin/bash

set -euo pipefail

# Determine the correct version, this is derived
# from the latest commit to the 'ci' branch in the code
# project, which is next door (../radar-pi)

if [ $# != 3 ]
then
  echo "Usage: $0 <project> <cloudsmith-user> <cloudsmith-repo>"
  echo ""
  exit 2
fi

PROJECT="${1}"
CLOUDSMITH_USER="${2}"
CLOUDSMITH_REPO="${3}"

function check_project_branch
{
  if [ ! -d "../${PROJECT}" ]
  then
    echo "$0: Cannot find project directory ../${PROJECT}"
    exit 1
  fi
  if (cd "../${PROJECT}"; git status) | grep -q "Your branch is up to date with 'origin/ci'" #> /dev/null 2>&1
  then
    return 0
  elif (cd "../${PROJECT}"; git status) | grep -q "Your branch is up-to-date with 'origin/ci'" #> /dev/null 2>&1
  then
    return 0
  fi
  echo "$0: The project directory ../${PROJECT} should be up to date with 'origin/ci'."
  exit 1
}

function check_plugin_branch
{
  local _branch

  case "${CLOUDSMITH_REPO}" in
    *-stable)
      _branch=master;;
    *)
      _branch=Beta;;
  esac

  if git status | grep -q "^On branch ${_branch}$" #> /dev/null 2>&1
  then
    return 0
  fi
  echo "$0: The plugins repo should be on branch ${_branch} as the Cloudsmith repo is ${CLOUDSMITH_REPO}"
  exit 1
}

function get_branch_commit
{
  (
    cd "../${PROJECT}"
    git rev-parse --short=7 HEAD
  )
}

function get_branch_tag
{
  (
    cd "../${PROJECT}"
    git tag --contains HEAD
  )
}

check_plugin_branch
check_project_branch

case "${CLOUDSMITH_REPO}" in
  *-stable)
    query="$(get_branch_tag)"
    echo "Downloading files for tag '$query'"
    ;;
  *)
    query="$(get_branch_commit)"
    echo "Downloading files for commit '$query'"
    ;;
esac


cd metadata
for url in $(
curl -s -S "https://api.cloudsmith.io/packages/${CLOUDSMITH_USER}/${CLOUDSMITH_REPO}/?page_size=9999&query=${query}" |
  jq -r '.[] |
         select(.extension == ".xml") |
         .cdn_url'
)
do
  echo $url
  # -r to clobber existing file
  file=$(basename "${url}")
  curl -s -S -o "${file}" "${url}"
done
