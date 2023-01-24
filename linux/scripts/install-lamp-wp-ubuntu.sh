#!/bin/bash
 
sudo apt install apache2 apache2-utils
sudo systemctl enable apache2
sudo systemctl start apache2
sudo a2enmod rewrite
sudo systemctl restart apache2
 
## открываем порт 80
sudo ufw allow in 80/tcp 
 
sudo mkdir /var/www/test.site
sudo chmod -R 755 /var/www
 
## test.site.conf
 
echo "127.0.0.1 test.site" | sudo tee -a >> /etc/hosts
 
## create database
sudo apt install mariadb-client mariadb-server
sudo mariadb -u root -p12345Tea -e "create database mdbtest; GRANT ALL PRIVILEGES ON mdbtest.* TO mdbuser@localhost IDENTIFIED BY 'mdbuser'"
 
sudo apt install php7.4 php7.4-mysql libapache2-mod-php7.4 php7.4-cli php7.4-cgi php7.4-gd
 
## wordpress
wget -c http://wordpress.org/latest.tar.gz
tar -xzvf latest.tar.gz
sudo rsync -av wordpress/* /var/www/test.site/
sudo chown -R www-data:www-data /var/www/test.site/
sudo chmod -R 755 /var/www/test.site/
