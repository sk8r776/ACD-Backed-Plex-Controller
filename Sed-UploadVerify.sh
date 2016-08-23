#!/bin/bash
for F in `find /opt/cloud/.local-sorted/ -type f`
do
        echo "---------------------------"
        FT=$( echo $F | rev | cut -d'/' -f 1 | rev | sed 's/-//g')
        FT1=$( echo $F | rev | cut -d'/' -f 1 | rev | cut -c 2-)
        FT2=$( echo $F | rev | cut -d'/' -f 1 | rev | cut -c 3-)
        if [[ $(acdcli f $FT) ]]; then
                echo "$FT"
                echo "Found on ACD, Deleting File"
                rm $F
        else
                if [[ $(acdcli f $FT1) ]]; then
                        echo "$FT1"
                        echo "Found on ACD, Deleting File"
                        rm $F
                else
                        if [[ $(acdcli f $FT2) ]]; then
                                echo "$FT2"
                                echo "Found on ACD, Deleting File"
                                rm $F
                        else
                                echo "Not Found on ACD, Leaving for next upload Attempt!"
                                echo "Tried the following names:"
                                echo "$FT"
                                echo "$FT1"
                                echo "$FT2"
                                echo "Orginal File name is:"
                                echo "$F"
                        fi

                fi
                echo "Not Found on ACD, Leaving for next upload Attempt!"
        fi
         echo "---------------------------"
done
