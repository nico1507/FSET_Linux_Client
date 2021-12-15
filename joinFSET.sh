 #!/bin/bash
 # FSET domain join script, v0.0.1
 # joins a clean install of openSuse to the FSET.STUVE.UNI-ULM.DE domain
 # run as root!
 
 # Autor:   Nicolas Graber
 # Contact: nicolas.graber@uni-ulm.de
 #          0731-50-17906


# static variables
ad_version=0
ad_config_version=0
security_config_version=0
printer_config_version=0
software_version=0

source ./ressources/func.sh

clear
print_logo
echo -e "##### FSET domain join #####\n\n"

# Basic checks at beginning
if ! [ $(id -u) = 0 ]
then
    echo -e "\n! Permission denied! You must run this script as root!" 1>&2 
    exit 1 
fi

mkdir -p /etc/fset
cd "$(dirname "$(readlink "$0")")"
read_version

while getopts hfvupP flag
    do
        case "${flag}" in
            h) print_help;;
            f) force_execution;;
            v) print_version;;
            u) unattended;;
            p) plain_install;;
            P) printer_config;;
        esac
    done
    
read_domainadmin
    
# initialize logfile
echo -e "##### FSET Domain join #####\n" > /etc/fset/join.log
echo -e "$(date), script version $scriptversion\n" >> /etc/fset/join.log
echo -e "\n"

# install required software
install_ad_software

# configure domain config files
configure_domain

# join domain
join_domain

# configure pam
configure_pam
configure_pam_mount

# set FSET branding
set_default_wallpaper

# install printers
install_printers

# install userspace software
install_user_software

# write current version
write_version

# clear variables
unset domainuser
unset domainpassword
