#!/bin/sh

# Shell script for quick installation
# nginx+php+mysql+phpmyadmin web server on Debian 6.

ROOT_DIR='/var/www'
LOGS_DIR="${ROOT_DIR}/logs"
SERVER_IP=$(hostname -i)

alert() {
  echo "\033[37;1;42m $@ \033[0m"
}

echo "
export PS1='\[\e]0;\w\a\]\n\[\e[32m\]\u@\h \[\e[33m\]\w\[\e[0m\]\n\$ '
alias ls='ls -la --color=auto'
alias grep='grep --color=auto'
alias nginx-restart='/etc/init.d/nginx restart'
alias php-restart='/etc/init.d/php-fcgi restart'
alias mysql-restart='/etc/init.d/mysql restart'
alias nginx-start='/etc/init.d/nginx start'
alias php-start='/etc/init.d/php-fcgi start'
alias mysql-start='/etc/init.d/mysql start'
alias nginx-stop='/etc/init.d/nginx stop'
alias php-stop='/etc/init.d/php-fcgi stop'
alias mysql-stop='/etc/init.d/mysql stop'
alias server-restart='nginx-restart; php-restart; mysql-restart;'
alias server-start='nginx-start; php-start; mysql-start;'
alias server-stop='nginx-stop; php-stop; mysql-stop;'" >> ~/.profile
alert 'Profile configured'

apt-get update -y
alert 'Updated'

apt-get upgrade -y
alert 'Upgraded'

apt-get install gcc openssl libssl-dev libpcre3-dev libbz2-dev vim mc git -y
alert 'Common packages installed'

wget -q -O - http://nginx.org/keys/nginx_signing.key | apt-key add -
alert 'Nginx package added'

apt-get update
apt-get install nginx -y
chmod +x /etc/init.d/nginx && insserv nginx
alert 'Nginx installed'

mv /etc/nginx/sites-available/default /etc/nginx/sites-available/default.old
mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.old
mkdir -p $ROOT_DIR
mkdir -p $LOGS_DIR
echo '<?php phpinfo(); ?>' > $ROOT_DIR/index.php
echo "
user          www-data;
pid           /var/run/nginx.pid;
worker_processes 4;

events {
    worker_connections 4096;
}

http {
    include       mime.types;
    default_type  application/octet-stream;
    access_log    off;
    #access_log    ${LOGS_DIR}/access.log;
    error_log     ${LOGS_DIR}/error.log;
    sendfile      on;
    tcp_nodelay   on;
    gzip          on;
    gzip_disable  \"MSIE [1-6]\.(?!.*SV1)\";

    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
" > /etc/nginx/nginx.conf
echo "
server {
    listen        [::]:80;
    server_name   localhost;
    root          ${ROOT_DIR};
    index         index.html index.htm index.php;

    location = /favicon.ico {
        access_log    off;
        log_not_found off;
    }

    location ~ \.php$ {
        try_files     \$uri = 404;
        fastcgi_pass  unix:/tmp/php.socket;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include       fastcgi_params;
    }
}

server {
    listen        8080;
    server_name   localhost;
    root          /usr/share/phpmyadmin;
    index         index.html index.htm index.php;

    location ~ \.php$ {
        try_files     \$uri = 404;
        fastcgi_pass  unix:/tmp/php.socket;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include       fastcgi_params;
    }
}
" > /etc/nginx/sites-available/default
alert 'Nginx configured'

apt-get install php5-cgi php5-mysql php5-curl -y
echo '#!/bin/bash
### BEGIN INIT INFO
# Provides:          php-cgi
# Required-Start:    networking
# Required-Stop:     networking
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start the PHP FastCGI daemon.
### END INIT INFO  
BIND=/tmp/php.socket
USER=www-data
PHP_FCGI_CHILDREN=2
PHP_FCGI_MAX_REQUESTS=5000  
PHP_CGI=/usr/bin/php-cgi
PHP_CGI_NAME=`basename $PHP_CGI`
PHP_CGI_ARGS="- USER=$USER PATH=/usr/bin PHP_FCGI_CHILDREN=$PHP_FCGI_CHILDREN PHP_FCGI_MAX_REQUESTS=$PHP_FCGI_MAX_REQUESTS $PHP_CGI -b $BIND"
RETVAL=0  
start() {
      echo -n "Starting PHP FastCGI: "
      start-stop-daemon --quiet --start --background --chuid "$USER" --exec /usr/bin/env -- $PHP_CGI_ARGS
      RETVAL=$?
      echo "$PHP_CGI_NAME."
}
stop() {
      echo -n "Stopping PHP FastCGI: "
      killall -q -w -u $USER $PHP_CGI
      RETVAL=$?
      echo "$PHP_CGI_NAME."
}  
case "$1" in
    start)
      start
  ;;
    stop)
      stop
  ;;
    restart)
      stop
      start
  ;;
    *)
      echo "Usage: php-fcgi {start|stop|restart}"
      exit 1
  ;;
esac
exit $RETVAL
' > /etc/init.d/php-fcgi
chmod +x /etc/init.d/php-fcgi && insserv php-fcgi
alert 'Php installed'

apt-get install mysql-server mysql-client -y
chmod +x /etc/init.d/mysql && insserv mysql
alert 'Mysql installed'

echo "
[client]
default-character-set = utf8
character-set-server = utf8
collation-server = utf8_general_ci
character-set-client = utf8
character-set-results = utf8
character-set-connection = utf8
[mysqld]
character_set_server=utf8
[server]
skip-character-set-client-handshake
" > /etc/mysql/conf.d/charset.cnf
alert 'Mysql configured'

apt-get install phpmyadmin -y
alert 'PhpMyAdmin installed'

/etc/init.d/nginx start
/etc/init.d/php-fcgi start
/etc/init.d/mysql start
alert 'Server started'

alert "Installation was successful! You can start the server with server-start. See what happened here - http://${SERVER_IP}/"
