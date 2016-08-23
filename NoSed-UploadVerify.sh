#!/bin/bash
for F in `find /opt/cloud/.local-sorted/ -type f`
do
        FT=$( echo $F | rev | cut -d'/' -f 1 | rev )
        echo "$FT"
        if [[ $(acdcli f $FT) ]]; then
                echo "Found on ACD, Deleting File"
                rm $F
        else
                echo "Not Found on ACD, Leaving for next upload Attempt!"
        fi
done
