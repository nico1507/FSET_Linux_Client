#!/bin/bash
if [ -d /tmp/$USER/profile/ ]
    if [ -d /tmp/$USER/profile/$USER.linux ]
    then
        rsync -xurl /tmp/$USER/profile/$USER.linux ~/
    else
        mkdir -p /tmp/$USER/profile/$SUER.linux
    fi
    (while : ; do; rsync -xurl /tmp/$USER/profile/$USER.linux ~/) &
fi
