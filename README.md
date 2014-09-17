node-nx is a free collection of shell scripts for rapid deployment of Nginx and Nodejs. I fork this scripts from popular [TuxLite](https://github.com/Mins/TuxLite).

Many changes here are inspired by [feross.org](http://feross.org/how-to-setup-your-linode/)

What Changes from upstream :

- Remove Apache, PHP, Varnish, Postfix, Awstat, Adminer / PHPMyAdmin
- Optimize settings for Production / Deployment settings. Turns on gzip by default. Turn off `access_log` and set `error_log` to be criticall only. See `config/nginx.conf` for more details
- Add usefull `MISC_PACKAGES`
- Email Anytime a user uses sudo
- Set usefull IPTables Configuration, from [http://feross.org/how-to-setup-your-linode/](http://feross.org/how-to-setup-your-linode/)
- Add cron jobs to keep mysql in tip-top shape
- (Future) glue nginx and nodejs together

### Quick Install (Git)

    # Install git and clone node-nx
    aptitude install git
    git clone https://github.com/rizalp/node-nx.git
    cd node-nx

    # Edit options to enter server IP, MySQL password etc.
    nano options.conf

    # Make all scripts executable.
    chmod 700 *.sh
    chmod 700 options.conf

    # Install
    ./install.sh

    # Add a new Linux user and add domains to the user.
    adduser johndoe
    ./domain.sh add johndoe yourdomain.com
    ./domain.sh add johndoe subdomain.yourdomain.com

### Optional : Prevent Repeated SSH Login attempts using Fail2Ban

Fail2Ban is a security tool to prevent dictionary attacks. It works by monitoring important services (like SSH) and blocking IP addresses which appear to be malicious (i.e. they are failing too many login attempts because they are guessing passwords).

Install Fail2Ban: `sudo aptitude install fail2ban`

Configure Fail2Ban:

    sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
    sudo nano /etc/fail2ban/jail.local

Set “enabled” to “true” in the [ssh-ddos] section. Also, set “port” to “880” in the [ssh] and [ssh-ddos] sections. (Change the port number to match whatever you used as your SSH port).

Restart the service `sudo service fail2ban restart`

### Optional : Reboot server on out-of-memory condition

Still, in cases where something goes awry, it is good to automatically reboot your server when it runs out of memory. This will cause a minute or two of downtime, but it’s better than languishing in the swapping state for potentially hours or days.

You can leverage a couple kernel settings and Lassie to make this happen on Linode.

Adding the following two lines to your `/etc/sysctl.conf` will cause it to reboot after running out of memory:

    vm.panic_on_oom=1
    kernel.panic=10

The `vm.panic_on_oom=1` line enables panic on OOM; the `kernel.panic=10` line tells the kernel to reboot ten seconds after panicking.

### Requirements

-   Only Debian >= 6, and Ubuntu >= 12.04 is supported
-   A server with at least 80MB RAM. 256MB and above recommended.
-   Basic Linux knowledge. You will need know how to connect to your
    server remotely.
-   Basic text editor knowledge. For beginners, learning GNU nano is
    recommended.

### License

The MIT License (MIT)

Copyright (c) 2014 Mohammad Shahrizal Prabowo

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
