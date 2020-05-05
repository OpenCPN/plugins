#!/bin/bash
#
#  Test tool which installs ań opencpn tarball directly,  without the
#  upload/download cycle. The installation is intended to be identical
#  with the plugin installer.
#
#  Dependencies:
#     bash and sed -- both of which available in linux and macos.
#     For windows, available in the git package.
#
#  Usage: 
#     ocpn-install.sh <tarball>
#

function abspath() {
    # Make path absolute
    # $1:      existing path, possibly relative
    # return:  absolute path
    if [ -d "$1" ]; then
        (cd "$1"; pwd)
    elif [ -f "$1" ]; then
        if [[ $1 = /* ]]; then
            echo "$1"
        elif [[ $1 == */* ]]; then
            echo "$(cd "${1%/*}"; pwd)/${1##*/}"
        else
            echo "$(pwd)/$1"
        fi
    else 
        echo "Cannot open: \"$1\" for read" >&2
        exit 1
    fi 
}



if [ $# -ne 1 ]; then
    echo "Usage: local-install.sh <tarball>" >&2
    exit 2
fi
if [ ! -f "$1" ]; then
    echo "Cannot find tarball file \"$1\""
    exit 1;
fi

readonly here=$(abspath $(dirname $0))
readonly tarball=$(abspath $1)
readonly filename=$(basename $tarball)
readonly plugin_piname=${filename%%-*}
readonly plugin_name=${plugin_piname%%_pi}
readonly tmpdir=$(mktemp -d)

echo "Unpacking tarball $tarball"
cd $tmpdir
tar --strip-components=1 -xf $tarball

case $filename in 
    *msvc*.tar.gz)
        basedir=$HOME/AppData/Local/opencpn
        installdir="/c/ProgramData/opencpn/plugins/install_data"
        ;;
    *flatpak*.tar.gz)
        basedir=$HOME/.var/app/org.opencpn.OpenCPN
        installdir="$HOME/.opencpn/plugins/install_data"
        ;;
    *ubuntu*.tar.gz | *debian*.tar.gz)
        basedir=$HOME/.local
        installdir="$HOME/.opencpn/plugins/install_data"
        ;;
    *darwin*.tar.gz)
        basedir=$HOME/Library/Application\ Support/OpenCPN/
        installdir="$HOME/Library/Preferences/plugins/"
        installdir="$installdir/${plugin_piname}/install_data"
esac
test -d $installdir || mkdir -p $installdir

manifest="$installdir/$plugin_name.files"
version_file="$installdir/$plugin_name.version"

if [ -f "$manifest" ]; then
    echo "Cleaning up old files in $basedir"
    rm -f $(cat $manifest) 2>/dev/null
    rm $manifest
fi

case $filename in 
    *msvc*.tar.gz | *mingw*.tar.gz)
        echo "Installing windows plugin into $basedir/{plugins,share}"
        tar -cf - plugins \
            | tar -vC $basedir -xf - \
            | sed -e "s|^|$basedir/|"  -e "s|/c/|C:/|" > $manifest
        tar -cf - share \
            | tar -vC $basedir -xf - \
            | sed -e "s|^|$basedir/|"  -e "s|/c/|C:/|" >> $manifest
        ;;

    *flatpak*.tar.gz)
        echo "Installing flatpak plugin into $basedir"
        tar -cf - bin lib \
            | tar -vC $basedir -xf - \
            | sed -e "s|^|$basedir/|"   > $manifest
        tar -cf - -C share locale opencpn \
            | tar -vC $basedir/data -xf - \
            | sed -e "s|^|$basedir/|"   >> $manifest
        ;;

    *ubuntu*.tar.gz | *debian*.tar.gz)
        echo "Installing linux plugin into $basedir"
        tar -cf - bin lib share \
            | tar -vC $basedir -xf - \
            | sed "s|^|$basedir/|" >$manifest
        ;;

    *darwin*.tar.gz)
        echo "Installing macos plugin into \"$basedir\""
        tar -cf - -C OpenCPN.app Contents \
            | tar -vC "$basedir" -xf - 2>&1 \
            | sed -e "s|^|$basedir/|" -e 's|/x ||'  > $manifest
        ;;
esac

for f in $(cat $manifest); do
    if [ -f "$f" ]; then count=$((count + 1)); fi
done
echo "$count files installed, manifest: $manifest"

readonly version=$(echo $tarball | sed -e 's/[^-]*-\([^_]*\)_.*/\1/')
echo "Rewriting version info using $version"
echo $version > $version_file

cd $here
rm -rf $tmpdir

