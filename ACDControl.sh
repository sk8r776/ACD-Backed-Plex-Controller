#!/bin/bash

if [ -z "$1" ]; then
        echo "The script must tbe run with the following syntax: ./ACDControl.sh Start|Stop|Restart|Sync"
        echo "This script provides the following options to manage ACD backed plex:"
        echo "Start - This will mount all drives, and start services"
        echo "Stop - This will unount all drive, and will not start services"
        echo "Restart - Will unmount all drives, mount them, and start services"
        echo "Sync - Will Sync all files in local encrypted share to ACD, remount drives, verify uploaded files, and start services"
        echo "Script not run correctly. Please run according to the instructions above!"
        exit 1
fi

if [[ $EUID -eq 0 ]]; then
   echo "Do NOT run this script as root!" 1>&2
   exit 1
fi

# Stop Services, anything we need to do will interfere
sudo systemctl stop plexmediaserver
sudo systemctl stop smb
sudo systemctl stop nmb

# Create Log for automated runs
touch $PWD/logs/ACDControl-$(date '+%F').log

## MOUNT LOCATIONS ##
ACDENCRYPTED='/opt/cloud/.acd-sorted'
ACDUNENCRYPTED='/opt/cloud/acd-sorted'
LOCALENCRYPTED='/opt/cloud/.local-sorted'
LOCALUNENCRYPTED='/opt/cloud/local-sorted'
UNIONFOLDER='/opt/cloud/shared/'

## ENCFS OPTIONS ##
ENCFSKEY='REVOKED'
ENCFSXML='/home/localadmin/encfs.xml'

if [ "$1" == "Start" ]; then
echo "Start routine selected..." >> $PWD/logs/ACDControl-$(date '+%F').log
acdcli old-sync >> $PWD/logs/ACDControl-$(date '+%F').log
acdcli mount $ACDENCRYPTED --allow-other --uid 1000 --gid 1000
        if mountpoint -q $ACDENCRYPTED; then
                sleep 3
                echo $ENCFSKEY | sudo -s ENCFS6_CONFIG=$ENCFSXML encfs -S --public -o umask=000,uid=1000,gid=1000 $ACDENCRYPTED $ACDUNENCRYPTED
                if mountpoint -q $ACDUNENCRYPTED; then
                        sleep 3
                        echo $ENCFSKEY | sudo -s ENCFS6_CONFIG=$ENCFSXML encfs -S --public -o umask=000,uid=1000,gid=1000 $LOCALENCRYPTED $LOCALUNENCRYPTED
                        if mountpoint -q $LOCALUNENCRYPTED; then
                                sleep 3
                                unionfs -o cow,umask=000,uid=1000,gid=1000,allow_other $LOCALUNENCRYPTED=RW:$ACDUNENCRYPTED=RO $UNIONFOLDER
                                if mountpoint -q $UNIONFOLDER; then
                                        sudo systemctl start plexmediaserver >> $PWD/logs/ACDControl-$(date '+%F').log
                                        sudo systemctl start smb >> $PWD/logs/ACDControl-$(date '+%F').log
                                        sudo systemctl start nmb >> $PWD/logs/ACDControl-$(date '+%F').log
                                        echo "All mounts are valid, and services have been started! (:" >> $PWD/logs/ACDControl-$(date '+%F').log
                                else
                                        echo "UnionFS did not mount" >> $PWD/logs/ACDControl-$(date '+%F').log
                                fi
                        else
                                echo "Local ENCFS did not mount" >> $PWD/logs/ACDControl-$(date '+%F').log
                        fi
                else
                        echo "ACD ENCFS did not mount" >> $PWD/logs/ACDControl-$(date '+%F').log
                fi
        else
                echo "ACD Did not mount" >> $PWD/logs/ACDControl-$(date '+%F').log
        fi
else
        if [ "$1" == "Stop" ]; then
                        echo "Stop routine selected..." >> $PWD/logs/ACDControl-$(date '+%F').log
                echo "It is possible to see some mount errors here." >> $PWD/logs/ACDControl-$(date '+%F').log
                echo "If mounte errors are shown, this indicated the last startup was not successful." >> $PWD/logs/ACDControl-$(date '+%F').log
                sudo umount $UNIONFOLDER
                sudo fusermount -u $LOCALUNENCRYPTED
                sudo fusermount -u $ACDUNENCRYPTED
                acdcli umount
        else
                if [ "$1" == "Restart" ]; then
                                echo "Restart routine selected..." >> $PWD/logs/ACDControl-$(date '+%F').log
                        echo "It is possible to see some mount errors here." >> $PWD/logs/ACDControl-$(date '+%F').log
                        echo "If mounte errors are shown, this indicated the last startup was not successful." >> $PWD/logs/ACDControl-$(date '+%F').log
                        sudo umount $UNIONFOLDER
                        sudo fusermount -u $LOCALUNENCRYPTED
                        sudo fusermount -u $ACDUNENCRYPTED
                        acdcli umount
                        sleep 3

                        acdcli old-sync >> $PWD/logs/ACDControl-$(date '+%F').log

                        sleep 5
                        acdcli mount $ACDENCRYPTED --allow-other --uid 1000 --gid 1000
                                if mountpoint -q $ACDENCRYPTED; then
                                        sleep 3
                                        echo $ENCFSKEY | sudo -s ENCFS6_CONFIG=$ENCFSXML encfs -S --public -o umask=000,uid=1000,gid=1000 $ACDENCRYPTED $ACDUNENCRYPTED
                                        if mountpoint -q $ACDUNENCRYPTED; then
                                                sleep 3
                                                echo $ENCFSKEY | sudo -s ENCFS6_CONFIG=$ENCFSXML encfs -S --public -o umask=000,uid=1000,gid=1000 $LOCALENCRYPTED $LOCALUNENCRYPTED
                                                if mountpoint -q $LOCALUNENCRYPTED; then
                                                        sleep 3
                                                        unionfs -o cow,umask=000,uid=1000,gid=1000,allow_other $LOCALUNENCRYPTED=RW:$ACDUNENCRYPTED=RO $UNIONFOLDER
                                                        if mountpoint -q $UNIONFOLDER; then
                                                                sudo systemctl start plexmediaserver >> $PWD/logs/ACDControl-$(date '+%F').log
                                                                sudo systemctl start smb >> $PWD/logs/ACDControl-$(date '+%F').log
                                                                sudo systemctl start nmb >> $PWD/logs/ACDControl-$(date '+%F').log
                                                                echo "All mounts are valid, and services have been started! (:" >> $PWD/logs/ACDControl-$(date '+%F').log
                                                        else
                                                                echo "UnionFS did not mount" >> $PWD/logs/ACDControl-$(date '+%F').log
                                                        fi
                                                else
                                                        echo "Local ENCFS did not mount" >> $PWD/logs/ACDControl-$(date '+%F').log
                                                fi
                                        else
                                                echo "ACD ENCFS did not mount" >> $PWD/logs/ACDControl-$(date '+%F').log
                                        fi
                                else
                                        echo "ACD Did not mount" >> $PWD/logs/ACDControl-$(date '+%F').log
                                fi
                else
                        if [ "$1" == "Sync" ]; then
                                        echo "Sync routine selected..." >> $PWD/logs/ACDControl-$(date '+%F').log
                                acdcli old-sync >> $PWD/logs/ACDControl-$(date '+%F').log
                                acdcli upload /opt/cloud/.local-sorted/* / >> $PWD/logs/ACDControl-$(date '+%F').log
                                        echo "It is possible to see some mount errors here." >> $PWD/logs/ACDControl-$(date '+%F').log
                                        echo "If mounte errors are shown, this indicated the last startup was not successful." >> $PWD/logs/ACDControl-$(date '+%F').log
                                        sudo umount $UNIONFOLDER
                                        sudo fusermount -u $LOCALUNENCRYPTED
                                        sudo fusermount -u $ACDUNENCRYPTED
                                        acdcli umount
                                        sleep 3

                                        echo "Syncing new upload changes with local cache" >> $PWD/logs/ACDControl-$(date '+%F').log
                                        acdcli old-sync >> $PWD/logs/ACDControl-$(date '+%F').log

                                        sleep 5
                                        acdcli mount $ACDENCRYPTED --allow-other --uid 1000 --gid 1000
                                                if mountpoint -q $ACDENCRYPTED; then
                                                        sleep 3
                                                        echo $ENCFSKEY | sudo -s ENCFS6_CONFIG=$ENCFSXML encfs -S --public -o umask=000,uid=1000,gid=1000 $ACDENCRYPTED $ACDUNENCRYPTED
                                                        if mountpoint -q $ACDUNENCRYPTED; then
                                                                sleep 3
                                                                echo $ENCFSKEY | sudo -s ENCFS6_CONFIG=$ENCFSXML encfs -S --public -o umask=000,uid=1000,gid=1000 $LOCALENCRYPTED $LOCALUNENCRYPTED
                                                                if mountpoint -q $LOCALUNENCRYPTED; then
                                                                        sleep 3
                                                                        unionfs -o cow,umask=000,uid=1000,gid=1000,allow_other $LOCALUNENCRYPTED=RW:$ACDUNENCRYPTED=RO $UNIONFOLDER
                                                                        if mountpoint -q $UNIONFOLDER; then
                                                                                echo "Starting upload verification, not cutting prefix hypens, if the upload was a lot of file this can take a while" >> $PWD/logs/ACDControl-$(date '+%F').log
                                                                                echo "To watch the upload verification in real time, oprn another window and run tail -f" "$PWD/logs/upload-NoSed-$(date '+%F').log" >> $PWD/logs/ACDControl-$(date '+%F').log
                                                                                ./NoSed-UploadVerify.sh > "logs/upload-NoSed-$(date '+%F').log" 2>&1
                                                                                echo "Starting upload verification, cutting prefix hypens, if the upload was a lot of file this can take a while" >> $PWD/logs/ACDControl-$(date '+%F').log
                                                                                echo "To watch the upload verification in real time, oprn another window and run tail -f" "$PWD/logs/upload-Sed-$(date '+%F').log" >> $PWD/logs/ACDControl-$(date '+%F').log
                                                                                ./Sed-UploadVerify.sh > "logs/upload-Sed-$(date '+%F').log" 2>&1
                                                                                sudo systemctl start plexmediaserver >> $PWD/logs/ACDControl-$(date '+%F').log
                                                                                sudo systemctl start smb >> $PWD/logs/ACDControl-$(date '+%F').log
                                                                                sudo systemctl start nmb >> $PWD/logs/ACDControl-$(date '+%F').log
                                                                                wget -q http://172.16.102.9:32400/library/sections/1/refresh?X-Plex-Token=qZWysyAetkq85Fs3E3Tg -O deleteme
                                                                                rm $PWD/deleteme
                                                                                wget -q http://172.16.102.9:32400/library/sections/2/refresh?X-Plex-Token=qZWysyAetkq85Fs3E3Tg -O deleteme
                                                                                rm $PWD/deleteme
                                                                                wget -q http://172.16.102.9:32400/library/sections/3/refresh?X-Plex-Token=qZWysyAetkq85Fs3E3Tg -O deleteme
                                                                                rm $PWD/deleteme
                                                                                echo "ACD backed Plex Sync Completed, see log for file verification!" >> $PWD/logs/ACDControl-$(date '+%F').log
                                                                        else
                                                                                echo "UnionFS did not mount" >> $PWD/logs/ACDControl-$(date '+%F').log
                                                                        fi
                                                                else
                                                                        echo "Local ENCFS did not mount" >> $PWD/logs/ACDControl-$(date '+%F').log
                                                                fi
                                                        else
                                                                echo "ACD ENCFS did not mount" >> $PWD/logs/ACDControl-$(date '+%F').log
                                                        fi
                                                else
                                                        echo "ACD Did not mount" >> $PWD/logs/ACDControl-$(date '+%F').log
                                                fi
                        fi
                fi
        fi
fi

