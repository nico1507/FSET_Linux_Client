 #!/bin/bash
 # FSET domain join script, v0.0.1
 # joins a clean install of openSuse to the FSET.STUVE.UNI-ULM.DE domain
 # run as root!
 
 # Autor:   Nicolas Graber
 # Contact: nicolas.graber@uni-ulm.de
 #          0731-50-17906


# static variables
scriptversion=0.0.1

#function definitions
install_ad_software() {
    printf "Installing required software for joining AD...\n" | tee -a /etc/fset/join.log
    zypper -n install krb5-client samba-client openldap2-client sssd sssd-tools sssd-ad pam_krb5 pam_mount >> /etc/fset/join.log
    printf "\nDone.\n" | tee -a /etc/fset/join.log
}

install_user_software() {
    printf "Installing user software... " | tee -a /etc/fset/join.log
    zypper -n install chromium thunderbird >> /etc/fset/join.log
    printf "Done.\n"
}

configure_domain() {
    printf "Configure domain config... "
    targetdir=/etc/krb5.conf
    command cp ./ressources/config_files/krb5.conf $targetdir
    chown root $targetdir
    chgrp root $targetdir
    chmod 644 $targetdir
    
    targetdir=/etc/samba/smb.conf
    command cp ./ressources/config_files/smb.conf $targetdir
    chown root $targetdir
    chgrp root $targetdir
    chmod 644 $targetdir
    
    targetdir=/etc/nsswitch.conf
    command cp ./ressources/config_files/nsswitch.conf $targetdir
    chown root $targetdir
    chgrp root $targetdir
    chmod 644 $targetdir
    
    targetdir=/etc/sssd/sssd.conf
    command cp ./ressources/config_files/sssd.conf $targetdir
    chown root $targetdir
    chgrp root $targetdir
    chmod 600 $targetdir
    
    targetdir=/etc/openldap/ldap.conf
    command cp ./ressources/config_files/ldap.conf $targetdir
    chown root $targetdir
    chgrp root $targetdir
    chmod 644 $targetdir
    printf "Done.\n" |  tee -a /etc/fset/join.log
}

join_domain() {
    printf "Joining domain... " |  tee -a /etc/fset/join.log
    echo $domainpassword | kinit $domainuser > /dev/null
    
    if ! [ $? -eq 0 ]
    then
        echo -e "\n! Error. Kinit failed. Abording." 1>&2 | tee -a /etc/fset/join.log
        exit 1
    fi
    
    printf "\n" >>/etc/fset/join.logfile
    net ads join -k >> /etc/fset/join.logfile
    printf "\n" >>/etc/fset/join.logfile
    
    if ! [ $? -eq 0 ]
    then
        echo -e "\n! Error. Net ADS Join failed. Abording." 1>&2 | tee -a /etc/fset/join.log
        exit 1
    fi
    
    printf "Success.\n"
}

configure_pam(){
    printf "Configuring PAM... " | tee -a /etc/fset/join.log
    pam-config -a --krb5-ignore_unknown_principals
    pam-config -a --sss
    pam-config -a --mkhomedir
    pam-config -a --localuser
    systemctl enable sssd > /dev/null
    systemctl start sssd
    printf "Done." | tee -a /etc/fset/join.log
}

configure_pam_mount(){
    printf "Configuring PAM Mount... " | tee -a /etc/fset/join.log
    targetdir=/etc/security/pam_mount.conf.xml
    command cp ./ressources/config_files/pam_mount.conf.xml $targetdir
    chown root $targetdir
    chgrp root $targetdir
    chmod 644 $targetdir
    
    targetdir=/etc/profile.d/profile_sync.sh
    command cp ./ressources/config_files/profile_sync.sh $targetdir
    chown root $targetdir
    chgrp root $targetdir
    chmod 644 $targetdir
}

set_default_wallpaper(){
    printf "Set default wallpaper... "
    targetdir=/etc/FSET/wallpaper.png
    command cp ./ressources/wallpapers/wallpaper.png $targetdir
    chown root $targetdir
    chgrp root $targetdir
    chmod 644 $targetdir

    targetdir=/etc/profile.d/set_default_wallpaper.sh
    command cp ./ressources/config_files/set_default_wallpaper.sh $targetdir
    chown root $targetdir
    chgrp root $targetdir
    chmod 644 $targetdir
}

clear
echo -e "##### FSET domain join #####\n\n"

# Basic checks at beginning
if ! [ $(id -u) = 0 ]
then
    echo -e "\n! Permission denied! You must run this script as root!" 1>&2 
    exit 1 
fi

if [ -e /etc/fset/joined ]
then 
    echo -e "\n! System already joined FSET. Script version: $(cat /etc/fset/joined)" 1>&2
    exit 1
fi

mkdir -p /etc/fset
cd "$(dirname "$(readlink "$0")")"

echo -e "### Basic configuration stuff: ###\n"
read -p "Enter Domain Admin Username: " domainuser
read -s -p "Enter Password: " domainpassword

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

#configure pam
configure_pam
configure_pam_mount

#set FSET branding
set_default_wallpaper

# clear variables
unset domainuser
unset domainpassword
