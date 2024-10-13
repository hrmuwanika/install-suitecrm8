#!/bin/sh
# Install SuiteCRM8 on Ubuntu 22.04

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
sudo add-apt-repository 'deb [arch=amd64,arm64,ppc64el] https://mariadb.mirror.liquidtelecom.com/repo/10.11/ubuntu jammy main'
sudo apt update

# Install PHP8.1
sudo apt install ca-certificates apt-transport-https software-properties-common -y
sudo add-apt-repository ppa:ondrej/php  -y
sudo apt update

# Install LAMP Server
sudo apt install apache2 -y

# start Apache service
sudo systemctl enable apache2 && sudo systemctl start apache2

sudo apt install mariadb-server -y

# By default, MariaDB is not secured. So, you will need to secure it. You can do this by running the mysql_secure_installation script:
# mysql_secure_installation

# start MariaDB service 
sudo systemctl start mariadb && sudo systemctl enable mariadb

sudo apt install php8.1 php8.1-cli php8.1-common php8.1-imap php8.1-redis php8.1-snmp php8.1-xml php8.1-zip php8.1-mbstring php8.1-curl \
libapache2-mod-php php8.1-gd php8.1-intl php8.1-mysql -y

# After that login to Mariadb Shell: 
mysql -u root -p << MYSQL_SCRIPT
CREATE USER 'suitecrm'@'localhost' IDENTIFIED BY 'm0d1fyth15';
CREATE DATABASE suitecrm;
GRANT ALL PRIVILEGES ON suitecrm.* TO 'suitecrm'@'localhost';
FLUSH PRIVILEGES;
EXIT;
MYSQL_SCRIPT

# Download SuiteCRM
mkdir /var/www/html/suitecrm
cd /var/www/html/suitecrm
wget https://sourceforge.net/projects/suitecrm/files/SuiteCRM-8.6.0.zip

# Extract the downloaded file
sudo apt install unzip -y

# Unzip and set the right permissions.
unzip SuiteCRM-8.6.0.zip
rm SuiteCRM-8.6.0.zip

# Next, copy the extracted directory to the Apache web root and give proper permissions:
chown -R www-data:www-data /var/www/html/suitecrm
chmod -R 755 /var/www/html/suitecrm

# Next, you will need to create an apache virtual host file for vTiger CRM. You can create it with the following command:
cat <<EOF > /etc/apache2/sites-available/suitecrm.conf

<VirtualHost *:80>
ServerName yourdomain.com
DocumentRoot /var/www/html/public

<Directory /var/www/html/>
AllowOverride All
</Directory>

ErrorLog ${APACHE_LOG_DIR}/error.log
CustomLog ${APACHE_LOG_DIR}/access.log combined

</VirtualHost>
EOF

# Enable the Apache configuration for SuiteCRM and rewrite the module.
sudo a2enmod rewrite
sudo a2ensite suitecrm.conf

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
