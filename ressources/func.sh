#function definitions
print_help(){
    printf "##### Options: #####\n\n  -h: Print this help page.\n  -v: Print deployed version.\n  -f: Force full script execution, even if system is up to date.\n  -p: Install all without userspace software.\n  -P: Install all without printers.\n  -u: Unattended mode without domain join.\n\n" 
    exit 0
}

print_version(){
    printf "Currently deployed version: $ad_version_cur.$ad_config_version_cur.$security_config_version_cur.$software_version_cur\n"
    exit 0
}

print_logo(){
    cat ./ressources/fset_logo.txt
    printf "\n\n"
}

force_execution(){
    ad_version_cur=-2
    ad_config_version_cur=-2
    security_config_version_cur=-2
    printer_config_version_cur=-2
    software_version_cur=-2
}

unattended(){
    ad_version_cur=1000
}

plain_install(){
    software_version=1000
}

read_domainadmin(){
if [ $ad_version_cur -lt $ad_version ]
then
    echo -e "### Basic configuration stuff: ###\n"
    read -p "Enter Domain Admin Username: " domainuser
    read -s -p "Enter Password: " domainpassword
fi
}

read_version(){
    ad_version_cur=-1
    ad_config_version_cur=-1
    security_config_version_cur=-1
    printer_config_version_cur=-2
    software_version_cur=-1
    if [ -d /etc/fset/ ]
    then
        if [ -e /etc/fset/version ]
        then
            ad_version_cur=$(sed -n '1p' /etc/fset/version)
            ad_config_version_cur=$(sed -n '2p' /etc/fset/version)
            security_config_version_cur=$(sed -n '3p' /etc/fset/version)
            printer_config_version_cur=$(sed -n '4p' /etc/fset/version)
            software_version_cur=$(sed -n '5p' /etc/fset/version)
        fi
    fi
}

write_version(){
    echo -e "$ad_version" > /etc/fset/version 
    echo -e "$ad_config_version" >> /etc/fset/version
    echo -e "$security_config_version" >> /etc/fset/version
    echo -e "$printer_config_version_cur" >> /etc/fset/version
    echo -e "$software_version" >> /etc/fset/version
}

install_ad_software() {
    printf "Installing required software for joining AD... " | tee -a /etc/fset/join.log
    if [ $ad_version_cur -lt $ad_version ] 
    then
        zypper -n install krb5-client samba-client openldap2-client sssd sssd-tools sssd-ad pam_krb5 pam_mount >> /etc/fset/join.log
        printf "Done.\n" | tee -a /etc/fset/join.log
    else
        printf "Already up to date.\n" | tee -a /etc/fset/join.log
    fi
}

install_user_software() {
    printf "Installing user software... " | tee -a /etc/fset/join.log
    if [ $software_version_cur -lt $software_version ]
    then
        zypper -n install chromium thunderbird gimp htop texmaker >> /etc/fset/join.log
        printf "Done.\n" | tee -a /etc/fset/join.log
    else
        printf "Already up to date.\n" | tee -a /etc/fset/join.log
    fi
}

configure_domain() {
    printf "Configure domain config... " |  tee -a /etc/fset/join.log
    if [ $ad_version_cur -lt $ad_version ] 
    then
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
        echo "134.60.40.149 fset-dea.fset.stuve.uni-ulm.de fset-dea.stuve.uni-ulm.de fset-dea" > /etc/hosts
        echo "134.60.28.81 fset-bfv.fset.stuve.uni-ulm.de fset-bfv.stuve.uni-ulm.de fset-bfv" > /etc/hosts
        printf "Done.\n" |  tee -a /etc/fset/join.log
    else
        printf "Already up to date.\n" |  tee -a /etc/fset/join.log
    fi
}

join_domain() {
    printf "Joining domain... " |  tee -a /etc/fset/join.log
    if [ $ad_version_cur -lt $ad_version ] 
    then
        echo $domainpassword | kinit $domainuser &>/dev/null
        
        if ! [ $? -eq 0 ]
        then
            echo -e "\n! Error. Kinit failed. Abording." 1>&2 | tee -a /etc/fset/join.log
            exit 1
        fi
        
        printf "\n" >>/etc/fset/join.logfile
        net ads join -k &>> /etc/fset/join.logfile
        printf "\n" >>/etc/fset/join.logfile
        
        if ! [ $? -eq 0 ]
        then
            echo -e "\n! Error. Net ADS Join failed. Abording." 1>&2 | tee -a /etc/fset/join.log
            exit 1
        fi
        printf "Success.\n" |  tee -a /etc/fset/join.log
    else
        printf "Already done.\n" |  tee -a /etc/fset/join.log
    fi
}

configure_pam(){
    printf "Configuring PAM... " | tee -a /etc/fset/join.log
    if [ $ad_config_version_cur -lt $ad_config_version ] 
    then
        pam-config -a --krb5-ignore_unknown_principals &>/dev/null
        pam-config -a --sss &>/dev/null
        pam-config -a --mkhomedir &>/dev/null
        pam-config -a --localuser &>/dev/null
        systemctl enable sssd &>/dev/null
        systemctl start sssd
        sed -i 's/^DISPLAYMANAGER_AUTOLOGIN.*$/DISPLAYMANAGER_AUTOLOGIN=""/' /etc/sysconfig/displaymanager
        sed -i 's/^DISPLAYMANAGER_AD_INTEGRATION.*$/DISPLAYMANAGER_AD_INTEGRATION=""/' /etc/sysconfig/displaymanager
        printf "Done.\n" | tee -a /etc/fset/join.log
    else 
        printf "Already done.\n" | tee -a /etc/fset/join.log
    fi
}

configure_pam_mount(){
    printf "Configuring PAM Mount... " | tee -a /etc/fset/join.log
    if [ $ad_config_version_cur -lt $ad_config_version ] 
    then
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
            
        pam-config --service sddm -a --mount &>/dev/null
        pam-config --service kde -a --mount &>/dev/null
        pam-config --service login -a --mount &>/dev/null
        pam-config --service sshd -a --mount &>/dev/null
        printf "Done.\n" | tee -a /etc/fset/join.log
    else
        printf "Already done.\n" | tee -a /etc/fset/join.log
    fi
}

set_default_wallpaper(){
    printf "Set default wallpaper... " | tee -a /etc/fset/join.log
    if [ $ad_config_version_cur -lt $ad_config_version ] 
    then
        targetdir=/etc/fset/wallpaper.png
        command cp ./ressources/wallpapers/wallpaper.png $targetdir
        chown root $targetdir
        chgrp root $targetdir
        chmod 644 $targetdir

        targetdir=/etc/profile.d/set_default_wallpaper.sh
        command cp ./ressources/config_files/set_default_wallpaper.sh $targetdir
        chown root $targetdir
        chgrp root $targetdir
        chmod 644 $targetdir
        cp ./ressources/wallpapers/wallpaper.jpg /usr/share/sddm/themes/breeze-openSUSE/components/artwork/1920x1080.jpg
        printf "Done.\n" | tee -a /etc/fset/join.log
    else
        printf "Already up to date.\n" | tee -a /etc/fset/join.log
    fi
} 

install_printers(){
    printf "Copy CUPS config... " | tee -a /etc/fset/join.log
    if [ $printer_config_version_cur -lt $printer_config_version ] 
    then
        command rm -R /etc/cups
        tar -xvf ./ressources/config_files/cups.tar -C /etc/ &> /dev/null
        chown root -R /etc/cups
        chgrp root -R /etc/cups
        chmod -R ugo+r /etc/cups/ppd
        systemctl restart cups
        printf "Done.\n" | tee -a /etc/fset/join.log
    else
        printf "Already up to date.\n" | tee -a /etc/fset/join.log
    fi
    
}

reboot_client(){
    if [ $ad_version_cur != 1000 ]
    then
    if [ $ad_config_version_cur -lt $ad_config_version -o $ad_version_cur -lt $ad_version -o $security_config_version_cur -lt $security_config_version ]
    then
        read -p "The script has finished. It is recommended to reboot the system before futher use. Do you want to reboot now? (y/n) " reboot_toggle
        if [ $reboot_toggle = "y" -o $reboot_toggle = "Y" ]
        then
            reboot
        fi
    fi
    fi
}

configure_firewall(){
    printf "Configure firewall... " | tee -a /etc/fset/join.log
    if [ $security_config_version_cur -lt $security_config_version ]
    then
        firewall-cmd --new-zone=uninetz --permanent &>/dev/null
        firewall-cmd --reload &>/dev/null
        firewall-cmd --zone=uninetz --add-source=134.60.0.0/16 --permanent &>/dev/null
        firewall-cmd --reload &>/dev/null
        firewall-cmd --zone=uninetz --add-service=ssh --permanent &>/dev/null
        firewall-cmd --reload &>/dev/null
        printf "Done.\n" | tee -a /etc/fset/join.log
    else
        printf "Already up to date.\n" | tee -a /etc/fset/join.log
    fi
}

activate_ssh(){
    if [ $security_config_version_cur -lt $security_config_version ]
    then
        printf "Enable ssh... " | tee -a /etc/fset/join.log
        systemctl enable sshd &>/dev/null
        systemctl start sshd &>/dev/null
        printf "Done.\n" | tee -a /etc/fset/join.log
    fi
}

configure_aliases(){
    if [ $security_config_version_cur -lt $security_config_version ]
    then
        printf "Configure aliases... " | tee -a /etc/fset/join.log
        echo $'alias force_logout=\'killall --user $USER\'' >> /etc/profile.d/alias.bash
        printf "Done.\n" | tee -a /etc/fset/join.log
    fi
}

configure_logout(){
    if [ $ad_config_version_cur -lt $ad_config_version ]
    then
        printf "Configure auto logout... " | tee -a /etc/fset/join.log
        sed -i 's/^DAILY_TIME.*$/DAILY_TIME="4:00"/' /etc/sysconfig/cron
        systemctl reload cron
        targetdir=/etc/cron.daily/logout_all_users.sh
        command cp ./ressources/config_files/logout_all_users.sh $targetdir
        chown root $targetdir
        chgrp root $targetdir
        chmod 755 $targetdir
        printf "Done.\n" | tee -a /etc/fset/join.log
    fi
}

clean_local_profiles(){
    if [ $ad_config_version_cur -lt $ad_config_version ]
    then
        printf "Configure deletion of local profiles... " | tee -a /etc/fset/join.log
        targetdir=/etc/cron.weekly/delete_old_profiles.sh
        command cp ./ressources/config_files/delete_old_profiles.sh $targetdir
        chown root $targetdir
        chgrp root $targetdir
        chmod 755 $targetdir
        printf "Done.\n" | tee -a /etc/fset/join.log
    fi
}
