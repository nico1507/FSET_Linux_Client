#!/bin/bash
if [ -d /etc/fset/git ]
then 
    cd /etc/fset/FSET_Linux_Client
    git pull
else
    cd /etc/fset/
    git clone https://github.com/nico1507/FSET_Linux_Client
fi
