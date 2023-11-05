#!/bin/sh
# Install vtiger CRM on Ubuntu 20.04

#--------------------------------------------------
# Update Server
#--------------------------------------------------
echo -e "\n============= Update Server ================"
sudo apt update && sudo apt -y upgrade 
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
sudo add-apt-repository 'deb [arch=amd64,arm64,ppc64el] https://mariadb.mirror.liquidtelecom.com/repo/10.8/ubuntu focal main'
sudo apt update

# Install PHP8.1
sudo apt install ca-certificates apt-transport-https software-properties-common -y
sudo add-apt-repository ppa:ondrej/php  -y
sudo apt update

# Install LAMP Server
sudo apt install apache2 mariadb-server mariadb-client libapache2-mod-php8.1 php8.1 php8.1-cli php8.1-mysql php8.1-common php8.1-zip php8.1-mbstring php8.1-xmlrpc \
php8.1-curl php8.1-soap php8.1-gd php8.1-xml php8.1-intl php8.1-ldap php8.1-imap php8.1-opcache unzip wget -y

# After installing all the packages, open php.ini file, and make some changes, close the file, and save  it:
cd /etc/php/8.1/apache2/
rm php.ini
wget https://githubusercontenet/hrmuwanika

# max_execution_time = 120
# max_input_vars = 2000
# memory_limit = 256M
# post_max_size = 128M
# upload_max_filesize = 128M
# file_uploads = On
# allow_url_fopen = On
# display_errors = On
# short_open_tags = Off
# log_errors = Off
# error_reporting = E_WARNING & ~E_NOTICE & ~E_DEPRECATED & ~E_STRICT

# Remove mariadb strict mode by setting sql_mode = NO_ENGINE_SUBSTITUTION
sudo rm /etc/mysql/mariadb.conf.d/50-server.cnf
cd /etc/mysql/mariadb.conf.d/
wget https://raw.githubusercontent.com/hrmuwanika/vicidial-install-scripts/main/50-server.cnf

# start Apache and MariaDB service and enable them to start on boot time with the following command:

systemctl start apache2
systemctl start mariadb

systemctl enable apache2
systemctl enable mariadb

# By default, MariaDB is not secured. So, you will need to secure it. You can do this by running the mysql_secure_installation script:
# mysql_secure_installation

# This script will change your current root password, remove anonymous users, disallow root login remotely as shown below:

# Enter current password for root (enter for none):
# Set root password? [Y/n]: N
# Remove anonymous users? [Y/n]: Y
# Disallow root login remotely? [Y/n]: Y
# Remove test database and access to it? [Y/n]:  Y
# Reload privilege tables now? [Y/n]:  Y

# After that login to Mariadb Shell: 
mysql -u root -p << MYSQL_SCRIPT
CREATE DATABASE vtigerdb;
CREATE USER 'vtiger'@'localhost' IDENTIFIED BY 'm0d1fyth15';
GRANT ALL PRIVILEGES ON vtiger.* TO 'vtiger'@'localhost';
FLUSH PRIVILEGES;
exit
MYSQL_SCRIPT

# Install vTiger CRM
cd /usr/src
wget https://excellmedia.dl.sourceforge.net/project/vtigercrm/vtiger%20CRM%208.0.0/Core%20Product/vtigercrm8.0.0.tar.gz

# Extract the downloaded file
tar -xvzf vtigercrm8.0.0.tar.gz

# Next, copy the extracted directory to the Apache web root and give proper permissions:
cp -r vtigercrm /var/www/html/
chown -R www-data:www-data /var/www/html/vtigercrm
chmod -R 755 /var/www/html/vtigercrm

# Next, you will need to create an apache virtual host file for vTiger CRM. You can create it with the following command:
cat <<EOF > /etc/apache2/sites-available/vtigercrm.conf

<VirtualHost *:80>
     ServerAdmin admin@example.com
     ServerName crm.example.com
     ServerAlias www.crm.example.com
     DocumentRoot /var/www/html/vtigercrm/

     <Directory /var/www/html/vtigercrm/>
       Options FollowSymlinks
       AllowOverride All
       Require all granted
     </Directory>

     ErrorLog /var/log/apache2/vtigercrm_error.log
     CustomLog /var/log/apache2/vtigercrm_access.log combined
</VirtualHost>

EOF

# Run the following command:
a2ensite vtigercrm
a2dissite 000-default

a2enmod rewrite

systemctl restart apache2
systemctl status apache2

ufw allow 80/tcp
ufw allow 443/tcp

# Now, open your web browser and type the URL localhost on browserm. 
# Click on the Install button. 
# accept the vTiger public licence. 
# verify installation prerequisites and click on the Next button.
# Next, provide your database name, database username, password, admin username and password. Then, click on the Next button.
# Next, select your industry and click on the Next button.
