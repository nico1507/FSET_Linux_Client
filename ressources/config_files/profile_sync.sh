#!/bin/bash
if [ -d /tmp/$USER/profile/ ]
    then
    if [ -d /tmp/$USER/profile/$USER.linux ]
    then
        rsync --delete -xurl /tmp/$USER/profile/$USER.linux/ ~/
    else
        mkdir -p /tmp/$USER/profile/$USER.linux
    fi
    (while :; do rsync ~/ --delete -xurl /tmp/$USER/profile/$USER.linux/; sleep 10m; done) & 
fi
