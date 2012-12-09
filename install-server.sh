#!/bin/sh

ROOT_DIR='/var/www'
SERVER_IP=$(hostname -i)

alert() {
  echo "\033[37;1;42m $@ \033[0m"
}

echo "" >> ~/.profile
echo "export PS1='\[\e]0;\w\a\]\n\[\e[32m\]\u@\h \[\e[33m\]\w\[\e[0m\]\n\$ '" >> ~/.profile
echo "alias ls='ls -la --color=auto'" >> ~/.profile
echo "alias grep='grep --color=auto'" >> ~/.profile
echo "alias nginx-restart='/etc/init.d/nginx restart'" >> ~/.profile
echo "alias php-restart='/etc/init.d/php-fcgi restart'" >> ~/.profile
echo "alias mysql-restart='/etc/init.d/mysql restart'" >> ~/.profile
echo "alias nginx-start='/etc/init.d/nginx start'" >> ~/.profile
echo "alias php-start='/etc/init.d/php-fcgi start'" >> ~/.profile
echo "alias mysql-start='/etc/init.d/mysql start'" >> ~/.profile
echo "alias nginx-stop='/etc/init.d/nginx stop'" >> ~/.profile
echo "alias php-stop='/etc/init.d/php-fcgi stop'" >> ~/.profile
echo "alias mysql-stop='/etc/init.d/mysql stop'" >> ~/.profile
echo "alias server-restart='nginx-restart; php-restart; mysql-restart;'" >> ~/.profile
echo "alias server-start='nginx-start; php-start; mysql-start;'" >> ~/.profile
echo "alias server-stop='nginx-stop; php-stop; mysql-stop;'" >> ~/.profile
. ~/.profile
alert 'Profile setted'

apt-get update -y
alert 'Updated'

apt-get upgrade -y
alert 'Upgraded'

apt-get install gcc openssl libssl-dev libpcre3-dev libbz2-dev vim mc -y
alert 'Common packages installed'

wget -q -O - http://nginx.org/keys/nginx_signing.key | apt-key add -
alert 'Nginx package added'

apt-get update
apt-get install nginx -y
chmod +x /etc/init.d/nginx && insserv nginx
alert 'Nginx installed'

mv /etc/nginx/sites-available/default /etc/nginx/sites-available/default.old
mkdir $ROOT_DIR
mkdir $ROOT_DIR/logs
echo '<?php phpinfo(); ?>' > $ROOT_DIR/index.php
echo "server {
    listen       [::]:80;
    server_name  localhost;
    root         ${ROOT_DIR};
    index        index.html index.htm index.php;
    access_log   ${ROOT_DIR}/logs/access.log;

    location ~ \.php$ {
        try_files \$uri = 404;
        fastcgi_pass   unix:/tmp/php.socket;
        fastcgi_index  index.php;
        fastcgi_param  SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
}

server {
    listen       8080;
    server_name  localhost;
    root         /usr/share/phpmyadmin/;
    index        index.html index.htm index.php;
    access_log   ${ROOT_DIR}/logs/access.log;

    location ~ \.php$ {
       fastcgi_pass   unix:/tmp/php.socket;
       fastcgi_index  index.php;
       fastcgi_param  SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
       include        fastcgi_params;
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

apt-get install phpmyadmin -y
alert 'PhpMyAdmin installed'

alert "Installation was successful! You can start the server with server-start. See what happened here - http://${SERVER_IP}/"