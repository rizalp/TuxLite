###############################################################################################
# nonjix - Complete Nodejs + Nginx setup script for Debian/Ubuntu                             #
# Email your questions to rizalp@gmail.com                                                    #
###############################################################################################

source ./options.conf

# Detect distribution. Debian or Ubuntu
DISTRO=`lsb_release -i -s`
# Distribution's release. Squeeze, wheezy, precise etc
RELEASE=`lsb_release -c -s`
if  [ $DISTRO = "" ]; then
    echo -e "\033[35;1mPlease run 'aptitude -y install lsb-release' before using this script.\033[0m"
    exit 1
fi


#### Functions Begin ####
function basic_server_setup {

    aptitude update && aptitude -y safe-upgrade

    # Reconfigure sshd - change port and disable root login
    sed -i 's/^Port [0-9]*/Port '${SSHD_PORT}'/' /etc/ssh/sshd_config
    sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
    service ssh reload

    # Set hostname and FQDN
    sed -i 's/'${SERVER_IP}'.*/'${SERVER_IP}' '${HOSTNAME_FQDN}' '${HOSTNAME}'/' /etc/hosts
    echo "$HOSTNAME" > /etc/hostname

    if [ $DISTRO = "Debian" ]; then
        # Debian system, use hostname.sh
        service hostname.sh start
    else
        # Ubuntu system, use hostname
        service hostname start
    fi

    # Basic hardening of sysctl.conf
    sed -i 's/^#net.ipv4.conf.all.accept_source_route = 0/net.ipv4.conf.all.accept_source_route = 0/' /etc/sysctl.conf
    sed -i 's/^net.ipv4.conf.all.accept_source_route = 1/net.ipv4.conf.all.accept_source_route = 0/' /etc/sysctl.conf
    sed -i 's/^#net.ipv6.conf.all.accept_source_route = 0/net.ipv6.conf.all.accept_source_route = 0/' /etc/sysctl.conf
    sed -i 's/^net.ipv6.conf.all.accept_source_route = 1/net.ipv6.conf.all.accept_source_route = 0/' /etc/sysctl.conf

    echo -e "\033[35;1m Root login disabled, SSH port set to $SSHD_PORT. Hostname set to $HOSTNAME and FQDN to $HOSTNAME_FQDN. \033[0m"
    echo -e "\033[35;1m Remember to create a normal user account for login or you will be locked out from your box! \033[0m"

} # End function basic_server_setup


function setup_apt {

    # If user enables apt option in options.conf
    if [ $CONFIGURE_APT = "yes" ]; then
        cp /etc/apt/{sources.list,sources.list.bak}

        if [ $DISTRO = "Debian" ]; then
            # Debian system, use Debian sources.list
            echo -e "\033[35;1mConfiguring APT for Debian. \033[0m"
            cat > /etc/apt/sources.list <<EOF
# Main repo
deb http://http.debian.net/debian $RELEASE main non-free contrib
deb-src http://http.debian.net/debian $RELEASE main non-free contrib
# Security
deb http://security.debian.org/ $RELEASE/updates main contrib non-free
deb-src http://security.debian.org/ $RELEASE/updates main contrib non-free

EOF
        fi # End if DISTRO = Debian


        if [ $DISTRO = "Ubuntu" ]; then
            # Ubuntu system, use Ubuntu sources.list
            echo -e "\033[35;1mConfiguring APT for Ubuntu. \033[0m"
            cat > /etc/apt/sources.list <<EOF
# Main repo
deb mirror://mirrors.ubuntu.com/mirrors.txt $RELEASE main restricted universe multiverse
deb-src mirror://mirrors.ubuntu.com/mirrors.txt $RELEASE main restricted universe multiverse

# Security & updates
deb mirror://mirrors.ubuntu.com/mirrors.txt $RELEASE-updates main restricted universe multiverse
deb-src mirror://mirrors.ubuntu.com/mirrors.txt $RELEASE-updates main restricted universe multiverse
deb mirror://mirrors.ubuntu.com/mirrors.txt $RELEASE-security main restricted universe multiverse
deb-src mirror://mirrors.ubuntu.com/mirrors.txt $RELEASE-security main restricted universe multiverse

EOF
        fi # End if DISTRO = Ubuntu


        #  Report error if detected distro is not yet supported
        if [ $DISTRO  != "Ubuntu" ] && [ $DISTRO  != "Debian" ]; then
            echo -e "\033[35;1mSorry, Distro: $DISTRO and Release: $RELEASE is not supported at this time. \033[0m"
            exit 1
        fi

    fi # End if CONFIGURE_APT = yes


    ## Third party mirrors ##

    # Add Dotdeb repo when using Debian 6.0 (squeeze)
    if  [ $DISTRO = "Debian" ] && [ $RELEASE = "squeeze" ]; then
        echo -e "\033[35;1mEnabling DotDeb repo for Debian 6.0 Squeeze. \033[0m"
        cat > /etc/apt/sources.list.d/dotdeb.list <<EOF
# Dotdeb
deb http://packages.dotdeb.org squeeze all
deb-src http://packages.dotdeb.org squeeze all

EOF
        wget http://www.dotdeb.org/dotdeb.gpg
        cat dotdeb.gpg | apt-key add -
    fi # End if DISTRO = Debian && RELEASE = squeeze


    # If user wants to install nginx from official repo and webserver=nginx
    if  [ $USE_NGINX_ORG_REPO = "yes" ] && [ $WEBSERVER = 1 ]; then
        echo -e "\033[35;1mEnabling nginx.org repo for Debian $RELEASE. \033[0m"
        cat > /etc/apt/sources.list.d/nginx.list <<EOF
# Official Nginx.org repository
deb http://nginx.org/packages/`echo $DISTRO | tr '[:upper:]' '[:lower:]'`/ $RELEASE nginx
deb-src http://nginx.org/packages/`echo $DISTRO | tr '[:upper:]' '[:lower:]'`/ $RELEASE nginx

EOF

        # Set APT pinning for Nginx package
        cat > /etc/apt/preferences.d/Nginx <<EOF
# Prevent potential conflict with main repo/dotdeb
# Always install from official nginx.org repo
Package: nginx
Pin: origin nginx.org
Pin-Priority: 1000

EOF
        wget http://nginx.org/packages/keys/nginx_signing.key
        cat nginx_signing.key | apt-key add -
    fi # End if USE_NGINX_ORG_REPO = yes && WEBSERVER = 1


    # If user wants to install MariaDB instead of MySQL
    if [ $INSTALL_MARIADB = 'yes' ]; then
        echo -e "\033[35;1mEnabling MariaDB.org repo for $DISTRO $RELEASE. \033[0m"
        cat > /etc/apt/sources.list.d/MariaDB.list <<EOF
# http://mariadb.org/mariadb/repositories/
deb $MARIADB_REPO`echo $DISTRO | tr [:upper:] [:lower:]` $RELEASE main
deb-src $MARIADB_REPO`echo $DISTRO | tr [:upper:] [:lower:]` $RELEASE main

EOF

        # Set APT pinning for MariaDB packages
        cat > /etc/apt/preferences.d/MariaDB <<EOF
# Prevent potential conflict with main repo that causes
# MariaDB to be uninstalled when upgrading mysql-common
Package: *
Pin: origin $MARIADB_REPO_HOSTNAME
Pin-Priority: 1000

EOF

        # Import MariaDB signing key
        apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 0xcbcb082a1bb943db
    fi # End if INSTALL_MARIADB = yes

    aptitude update
    echo -e "\033[35;1m Successfully configured /etc/apt/sources.list \033[0m"

} # End function setup_apt


function install_webserver {

    if [ $WEBSERVER = 1 ]; then
        aptitude -y install nginx

        if  [ $USE_NGINX_ORG_REPO = "yes" ]; then
            mkdir /etc/nginx/sites-available
            mkdir /etc/nginx/sites-enabled

           # Disable vhost that isn't in the sites-available folder. Put a hash in front of any line.
           sed -i 's/^[^#]/#&/' /etc/nginx/conf.d/default.conf

           # Enable default vhost in /etc/nginx/sites-available
           ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default
        fi

        # Add a catch-all default vhost
        cat ./config/nginx_default_vhost.conf > /etc/nginx/sites-available/default

        # Change default vhost root directory to /usr/share/nginx/html;
        sed -i 's/\(root \/usr\/share\/nginx\/\).*/\1html;/' /etc/nginx/sites-available/default

    fi

} # End function install_webserver


function install_extras {

    if [ $AWSTATS_ENABLE = 'yes' ]; then
        aptitude -y install awstats
    fi

    # Install any other packages specified in options.conf
    aptitude -y install $MISC_PACKAGES

} # End function install_extras


function install_mysql {

    echo "mysql-server mysql-server/root_password password $MYSQL_ROOT_PASSWORD" | debconf-set-selections
    echo "mysql-server mysql-server/root_password_again password $MYSQL_ROOT_PASSWORD" | debconf-set-selections

    if [ $INSTALL_MARIADB = 'yes' ]; then
        aptitude -y install mariadb-server mariadb-client
    else
        aptitude -y install mysql-server mysql-client
    fi

    echo -e "\033[35;1m Securing MySQL... \033[0m"
    sleep 5

    aptitude -y install expect

    SECURE_MYSQL=$(expect -c "
        set timeout 10
        spawn mysql_secure_installation
        expect \"Enter current password for root (enter for none):\"
        send \"$MYSQL_ROOT_PASSWORD\r\"
        expect \"Change the root password?\"
        send \"n\r\"
        expect \"Remove anonymous users?\"
        send \"y\r\"
        expect \"Disallow root login remotely?\"
        send \"y\r\"
        expect \"Remove test database and access to it?\"
        send \"y\r\"
        expect \"Reload privilege tables now?\"
        send \"y\r\"
        expect eof
    ")

    echo "$SECURE_MYSQL"
    aptitude -y purge expect

} # End function install_mysql


function optimize_stack {

    if [ $WEBSERVER = 1 ]; then
        cat ./config/nginx.conf > /etc/nginx/nginx.conf

        # Change nginx user from  "www-data" to "nginx".
        if  [ $USE_NGINX_ORG_REPO = "yes" ]; then
            sed -i 's/^user\s*www-data/user nginx/' /etc/nginx/nginx.conf
        fi

        # Change logrotate for nginx log files to keep 10 days worth of logs
        nginx_file=`find /etc/logrotate.d/ -maxdepth 1 -name "nginx*"`
        sed -i 's/\trotate .*/\trotate 10/' $nginx_file
    fi

    if [ $AWSTATS_ENABLE = 'yes' ]; then
        # Configure AWStats
        temp=`grep -i sitedomain /etc/awstats/awstats.conf.local | wc -l`
        if [ $temp -lt 1 ]; then
            echo SiteDomain="$HOSTNAME_FQDN" >> /etc/awstats/awstats.conf.local
        fi
        # Disable Awstats from executing every 10 minutes. Put a hash in front of any line.
        sed -i 's/^[^#]/#&/' /etc/cron.d/awstats
    fi

    # Generating self signed SSL certs
    echo -e " "
    echo -e "\033[35;1m Generating self signed SSL cert... \033[0m"
    mkdir /etc/ssl/localcerts

    aptitude -y install expect

    GENERATE_CERT=$(expect -c "
        set timeout 10
        spawn openssl req -new -x509 -days 3650 -nodes -out /etc/ssl/localcerts/webserver.pem -keyout /etc/ssl/localcerts/webserver.key
        expect \"Country Name (2 letter code) \[AU\]:\"
        send \"\r\"
        expect \"State or Province Name (full name) \[Some-State\]:\"
        send \"\r\"
        expect \"Locality Name (eg, city) \[\]:\"
        send \"\r\"
        expect \"Organization Name (eg, company) \[Internet Widgits Pty Ltd\]:\"
        send \"\r\"
        expect \"Organizational Unit Name (eg, section) \[\]:\"
        send \"\r\"
        expect \"Common Name (eg, YOUR name) \[\]:\"
        send \"\r\"
        expect \"Email Address \[\]:\"
        send \"\r\"
        expect eof
    ")

    echo "$GENERATE_CERT"
    aptitude -y purge expect

#Email Anytime a user uses sudo
cat >> /etc/sudoers.d/my_sudoers <<EOF
Defaults    mail_always
Defaults    mailto="${mailto_sudo}"
EOF
chmod 0440 /etc/sudoers.d/my_sudoers

# IPTables
cat ./config/iptables.conf >> /etc/iptables.firewall.rules
iptables-restore < /etc/iptables.firewall.rules
cat >> /etc/network/if-pre-up.d/firewall <<EOF
#!/bin/sh
/sbin/iptables-restore < /etc/iptables.firewall.rules
EOF
chmod +x /etc/network/if-pre-up.d/firewall

#Keep MySQL tables in tip-top shape
crontab -l > tempCron
cat >> tempCron <<EOF
@weekly mysqlcheck -o --user=root --password=$MYSQL_ROOT_PASSWORD -A
EOF
crontab tempCron
rm tempCron

    restart_webserver
    sleep 2
    echo -e "\033[35;1m Optimize complete! \033[0m"

} # End function optimize


function install_postfix {

    # Install postfix
    echo "postfix postfix/main_mailer_type select Internet Site" | debconf-set-selections
    echo "postfix postfix/mailname string $HOSTNAME_FQDN" | debconf-set-selections
    echo "postfix postfix/destinations string localhost.localdomain, localhost" | debconf-set-selections
    aptitude -y install postfix

    # Allow mail delivery from localhost only
    /usr/sbin/postconf -e "inet_interfaces = loopback-only"

    sleep 1
    postfix stop
    sleep 1
    postfix start

} # End function install_postfix


function restart_webserver {

    if [ $WEBSERVER = 1 ]; then
        service nginx restart

    fi

} # End function restart_webserver


#### Main program begins ####

# Show Menu
if [ ! -n "$1" ]; then
    echo ""
    echo -e  "\033[35;1mNOTICE: Edit options.conf before using\033[0m"
    echo -e  "\033[35;1mA standard setup would be: apt + basic + install + optimize\033[0m"
    echo ""
    echo -e  "\033[35;1mSelect from the options below to use this script:- \033[0m"

    echo -n "$0"
    echo -ne "\033[36m apt\033[0m"
    echo     " - Reconfigure or reset /etc/apt/sources.list."

    echo -n  "$0"
    echo -ne "\033[36m basic\033[0m"
    echo     " - Disable root SSH logins, change SSH port and set hostname."

    echo -n "$0"
    echo -ne "\033[36m install\033[0m"
    echo     " - Installs LNMP or LAMP stack. Also installs Postfix MTA."

    echo -n "$0"
    echo -ne "\033[36m optimize\033[0m"
    echo     " - Optimizes webserver.conf, php.ini, AWStats & logrotate. Also generates self signed SSL certs."

    echo ""
    exit
fi
# End Show Menu


case $1 in
apt)
    setup_apt
    ;;
basic)
    basic_server_setup
    ;;
install)
    install_webserver
    install_mysql
    install_extras
    install_postfix
    restart_webserver
    ;;
optimize)
    optimize_stack
    ;;
esac


