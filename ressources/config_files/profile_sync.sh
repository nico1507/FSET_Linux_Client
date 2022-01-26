#!/bin/bash
if [ -d /tmp/$USER/profile/ ]
    then
    if [ -d /tmp/$USER/profile/$USER.linux ]
    then
        rsync --exclude '.local' --exclude '.cache' --delete -xurl /tmp/$USER/profile/$USER.linux/ ~/
    else
        mkdir -p /tmp/$USER/profile/$USER.linux
    fi
    (while :; do rsync ~/ --exclude '.local' --exclude '.cache' --delete -xurl /tmp/$USER/profile/$USER.linux/; sleep 5m; done) & disown
fi
