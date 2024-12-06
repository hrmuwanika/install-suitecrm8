#!/bin/sh
# Install SuiteCRM 8 on Ubuntu 22.04

#--------------------------------------------------
# Update Server
#--------------------------------------------------
echo -e "\n============= Update Server ================"
sudo apt update -y && sudo apt upgrade -y
sudo apt autoremove -y

#--------------------------------------------------
# Set up the timezones
#--------------------------------------------------
# set the correct timezone on ubuntu
timedatectl set-timezone Africa/Kigali
timedatectl

#----------------------------------------------------
# Disable password authentication
#----------------------------------------------------
sudo sed -i 's/#ChallengeResponseAuthentication yes/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/UsePAM yes/UsePAM no/' /etc/ssh/sshd_config 
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo service sshd restart

# Install mariadb databases
sudo apt-key adv --fetch-keys 'https://mariadb.org/mariadb_release_signing_key.asc'
sudo add-apt-repository 'deb [arch=amd64,arm64,ppc64el] https://mariadb.mirror.liquidtelecom.com/repo/10.11/ubuntu jammy main'
sudo apt update

# Install PHP8.1
sudo apt install ca-certificates apt-transport-https software-properties-common -y
sudo add-apt-repository ppa:ondrej/php  -y
sudo apt update

sudo apt install wget curl nano ufw software-properties-common dirmngr apt-transport-https gnupg2 ca-certificates lsb-release ubuntu-keyring unzip -y

# Install LAMP Server
sudo apt install apache2 -y

# start Apache service
sudo systemctl enable apache2 && sudo systemctl start apache2

sudo apt install mariadb-server -y

# By default, MariaDB is not secured. So, you will need to secure it. You can do this by running the mysql_secure_installation script:
# sudo mariadb_secure_installation

# start MariaDB service 
sudo systemctl start mariadb && sudo systemctl enable mariadb

sudo apt install php8.1 php8.1-cli php8.1-bcmath php8.1-common php8.1-imap php8.1-redis php8.1-snmp php8.1-xml php8.1-zip php8.1-mbstring php8.1-curl \
libapache2-mod-php php8.1-gd php8.1-intl php8.1-mysql php8.1-gd php8.1-opcache php8.1-soap php8.1-ldap php-imagick php8.1-json php8.1-bz2 php8.1-gmp -y

# Configure PHP
sudo nano /etc/php/8.1/apache2/php.ini
sudo nano /etc/php/8.1/cli/php.ini

date.timezone = Africa/Kigali
post_max_size = 60M
upload_max_filesize = 60M
memory_limit = 256M
max_input_time = 60
max_execution_time = 5000
cgi.fix_pathinfo=0
error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT & ~E_NOTICE & ~E_WARNING
session.save_path = "/var/lib/php/sessions"
opcache.enable=1

sudo systemctl restart apache2

# After that login to Mariadb Shell: 
mysql -u root -p << MYSQL_SCRIPT
CREATE USER 'suitecrmuser'@'localhost' IDENTIFIED BY 'm0d1fyth15';
CREATE DATABASE suitecrmdb;
GRANT ALL PRIVILEGES ON suitecrmdb.* TO 'suitecrmuser'@'localhost';
FLUSH PRIVILEGES;
EXIT;
MYSQL_SCRIPT

# Download SuiteCRM
cd /usr/src
wget https://suitecrm.com/download/148/suite87/564667/suitecrm-8-7-1.zip
mkdir /var/www/html/crm
sudo unzip SuiteCRM-8.7.1.zip -d /var/www/html/crm
rm SuiteCRM-8.7.1.zip

# Next, copy the extracted directory to the Apache web root and give proper permissions:
sudo chown -R www-data:www-data /var/www/html/crm
sudo chmod -R 755 /var/www/html/crm

# Next, you will need to create an apache virtual host file for vTiger CRM. You can create it with the following command:
cat <<EOF > /etc/apache2/sites-available/suitecrm.conf

<VirtualHost *:80>
ServerName yourdomain.com
DocumentRoot /var/www/html/crm

<Directory /var/www/html/crm>
Options FollowSymLinks
AllowOverride All
</Directory>

ErrorLog /var/log/apache2/suitecrm-error.log
CustomLog /var/log/apache2/suitecrm-access.log common

</VirtualHost>
EOF

# Enable the Apache configuration for SuiteCRM and rewrite the module.
sudo a2enmod rewrite
sudo a2ensite suitecrm.conf

apachectl -t

sudo systemctl restart apache2
sudo systemctl status apache2

# Configure firewall
sudo ufw allow OpenSSH
sudo ufw allow http
sudo ufw allow https
sudo ufw enable

# Install and Configure SSL
sudo apt install snapd -y
sudo snap install core 
sudo snap refresh core
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot

# Now, open your web browser and type the URL localhost on browser. 
# https://yourdomain.com/crm/public 
