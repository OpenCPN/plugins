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
#     See usage()
#


function usage() {
cat << EOF
Usage:
   ocpn-install.sh <tarball>  <metadata>

Parameters
   tarball: tar.gz plugin archive aimed to be installed by installer.
   metadata: xml file with metadata, used to build catalog.

See:
   https://github.com/leamas/opencpn/wiki/Tarballs
   https://github.com/leamas/opencpn/wiki/Catalog

EOF
}

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

function parse_metadata()
{
    tmpfile=$(mktemp)
cat << EOF > $tmpfile
import sys, xml.etree.ElementTree as ET

tree = ET.parse(sys.argv[1])
version = tree.find("./version").text.strip()
name = tree.find("./name").text.strip()
print("%s=%s" % (name, version))
EOF
    python3 $tmpfile $1 && rm $tmpfile
}


if [ $# -ne 2 ]; then
    usage;
    exit 2
fi
if [ "$1" == '-h' -o "$1" 0 '--help' ]; then
    usage;
    exit 0
fi
if [ ! -f "$1" ]; then
    echo "Cannot find tarball file \"$1\""
    exit 1;
fi
if [ ! -f "$2" ]; then
    echo "Cannot find metadata file \"$2\""
    exit 1;
fi

readonly here=$(abspath $(dirname $0))
readonly tarball=$(abspath $1)
readonly metadata=$(abspath $2)
readonly filename=$(basename $tarball)
readonly plugin_piname=${filename%%-*}
readonly tmpdir=$(mktemp -d)
name_vers="$(parse_metadata $metadata)"
readonly plugin_name="${name_vers%=*}"
readonly meta_vers="${name_vers##*=}"


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
    *ubuntu*.tar.gz | *debian*.tar.gz | *raspbian*.tar.gz)
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
    rm -f $(sed -e 's/$/"/' -e 's/^/"/' "$manifest") 2>/dev/null
    rm "$manifest"
fi

case $filename in 
    *msvc*.tar.gz | *mingw*.tar.gz)
        echo "Installing windows plugin into $basedir/{plugins,share}"
        tar -cf - plugins \
            | tar -vC $basedir -xf - \
            | sed -e "s|^|$basedir/|"  -e "s|/c/|C:/|" > "$manifest"
        tar -cf - share \
            | tar -vC $basedir -xf - \
            | sed -e "s|^|$basedir/|"  -e "s|/c/|C:/|" >> "$manifest"
        ;;

    *flatpak*.tar.gz)
        echo "Installing flatpak plugin into $basedir"
        tar -cf - bin lib \
            | tar -vC $basedir -xf - \
            | sed -e "s|^|$basedir/|"   > "$manifest"
        tar -cf - -C share locale opencpn \
            | tar -vC $basedir/data -xf - \
            | sed -e "s|^|$basedir/|"   >> "$manifest"
        ;;

    *ubuntu*.tar.gz | *debian*.tar.gz | *raspbian*.tar.gz)
        if [ -d usr ]; then cd usr; fi
        if [ -d local ]; then cd local; fi
        echo "Installing linux plugin into $basedir"
        tar -cf - bin lib share \
            | tar -vC $basedir -xf - \
            | sed "s|^|$basedir/|" >"$manifest"
        ;;

    *darwin*.tar.gz)
        echo "Installing macos plugin into \"$basedir\""
        tar -cf - -C OpenCPN.app Contents \
            | tar -vC "$basedir" -xf -? 2>&1 \
            | sed -e "s|^|$basedir/|" -e 's|/x ||'  > "$manifest"
        ;;
esac

echo "Plugin common name: $plugin_name"

count=0
for f in $(cat "$manifest"); do
    if [ -f  $f ]; then count=$((count + 1)); fi
done
echo "$count files installed, manifest: $manifest"

readonly version=$(echo $tarball | sed -e 's/[^-]*-\([^_]*\)_.*/\1/')
echo "Rewriting version info using $version"
echo $version > "$version_file"

cd $here
rm -rf $tmpdir
