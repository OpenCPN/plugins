#!/bin/bash
echo "This script is now redundant and calls 'download_xml.sh' to process the request."
read -n 1 -s -p "Press any key to continue..."
bash ./download_xml.sh $*
exit
