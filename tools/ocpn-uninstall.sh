#!/bin/bash
#
#  Test tool which uninstalls a plugin from the command line.
#
#  Dependencies:
#     bash  -- available in linux and macos.
#     For windows, available in the git package.
#
#  Usage: See usage()
#

function usage() {
     cat << EOF
Usage: ocpn-uninstall.sh <plugin> <platform | manifest>
Parameters:
    plugin:    Name of plugin, typically with a _pi suffix.
    platform:  windows, linux, darwin or flatpak.
    manifest:  Path to installation manifest, as printed at installation
Example:
    ./ocpn-uninstall.sh oesenc_pi windows
EOF
}


if [ $# -ne 2 ]; then
    usage >&2;
    exit 2
fi
platform=$2
plugin=$1

if [ -f "$platform" ]; then
    manifest=$platform
else
    case $platform in
        windows)
            installdir="/c/ProgramData/opencpn/plugins/install_data"
            ;;
        flatpak)
            installdir="$HOME/.opencpn/plugins/install_data"
            ;;
        linux)
            installdir="$HOME/.opencpn/plugins/install_data"
            ;;
        darwin | macos)
            installdir="$HOME/Library/Preferences/plugins/"
            installdir="$installdir/${plugin}/install_data"
            ;;
        *)
            echo  "Unknown platform: $platform" >&2
            usage >&2
            exit 2
            ;;
    esac
    manifest="$installdir/${plugin%%_pi}.files"
fi

if [ ! -f "$manifest" ]; then
    echo -e "Cannot locate manifest file: $manifest\nGiving up."  >&2
    exit 2;
fi

count=0
for f in $(cat $manifest); do
    test -f "$f" || continue
    rm -f "$f"
    count=$((count + 1))
done

echo "Removed $count files + manifest"
rm -f $manifest