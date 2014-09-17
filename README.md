### node-nx Readme

Ganti IF dengan ""

node-nx is a free collection of shell scripts for rapid deployment of Nginx, Nodejs, and PostgreSQL. I fork this scripts from popular [TuxLite](https://github.com/Mins/TuxLite).

What Changes from upstream :

- Remove Apache, PHP, Varnish, Postfix, Awstat
- Using PostgreSQL instead of MariaDB / MySQL
- Install NodeJS though NV
- Optimize settings for Production / Deployment settings
- Adminer / PHPMyAdmin. Managing your database should be done on secure host


For more detailed explanation on the installation, usage and script features,
kindly refer to these links:-

[Installation](#)

[Script features](#)

[Download](#)

### Quick Install (Git)

    # Install git and clone nonjix
    aptitude install git
    git clone https://github.com/Mins/nonjix.git
    cd nonjix

    # Edit options to enter server IP, MySQL password etc.
    nano options.conf

    # Make all scripts executable.
    chmod 700 *.sh
    chmod 700 options.conf

    # Install LAMP or LNMP stack.
    ./install.sh

    # Add a new Linux user and add domains to the user.
    adduser johndoe
    ./domain.sh add johndoe yourdomain.com
    ./domain.sh add johndoe subdomain.yourdomain.com

    # Enable/disable public viewing of Adminer/phpMyAdmin
    ./domain.sh dbgui on
    ./domain.sh dbgui off

### Requirements

-   Supports Debian 6 and 7, Ubuntu 12.04, 12.10 and 13.04.
-   A server with at least 80MB RAM. 256MB and above recommended.
-   Basic Linux knowledge. You will need know how to connect to your
    server remotely.
-   Basic text editor knowledge. For beginners, learning GNU nano is
    recommended.

If this is your first time with a Linux server, I suggest spending a day
reading the "getting started" tutorials in Linode Library.

### Why use nonjix?

-   nonjix LAMP stack configures Apache with mpm\_event and PHP with
    fastcgi (PHP-FPM). This gives much higher performance and lower memory
    consumption than the regular LAMP tutorials/guides using mod\_php.
-   Uses official distribution packages. You are not at the mercy of the
    script maintainer to keep your servers updated. All installed
    software are tuned, optimized and secured.
-   Minimal resource usage. Fresh install requires only 50-60MB RAM.
-   Free from unnecessary or custom changes to your server. Everything
    is configured according to Debian/Ubuntu standards.
-   Automatic virtualhost configuration with log rotation, AWStats
    traffic statistics and phpMyAdmin for managing MySQL.
-   Varnish cache script included to turbo charge your websites.
-   Free and open source! Coded in a human readable manner and
    modular, making custom modifications extremely easy.
