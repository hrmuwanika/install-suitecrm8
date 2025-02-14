#!/bin/sh
# Install SuiteCRM 8 on Ubuntu 24.04

# Variable
# Set to "True" to install certbot and have ssl enabled, "False" to use http
ENABLE_SSL="True"
# Set the website name
WEBSITE_NAME="example.com"
# Provide Email to register ssl certificate
ADMIN_EMAIL="moodle@example.com"
PHP_VERSION="8.3"

#--------------------------------------------------
# Update Server
#--------------------------------------------------
echo "============= Update Server ================"
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

# Install PHP8.3
sudo apt install ca-certificates apt-transport-https software-properties-common -y
sudo add-apt-repository ppa:ondrej/php  -y
sudo apt update

sudo apt install -y wget curl nano ufw software-properties-common dirmngr apt-transport-https gnupg2 ca-certificates lsb-release ubuntu-keyring unzip 

# Install Apache Server
sudo apt install apache2 -y

# start Apache service
sudo systemctl enable apache2 
sudo systemctl start apache2

sudo apt install mariadb-server mariadb-client -y

# Secure Mariadb database
# sudo mariadb_secure_installation

# start MariaDB service 
sudo systemctl start mariadb 
sudo systemctl enable mariadb

sudo apt install -y php php-cli php-bcmath php-common php-imap php-redis php-snmp php-xml php-zip php-mbstring php-curl \
libapache2-mod-php php-gd php-intl php-mysql php-gd php-soap php-ldap php-imagick php-json php-bz2 php-gmp 

# Configure PHP
echo "Configuring PHP..."
sudo sed -i "s/upload_max_filesize\ =\ 2M/upload_max_filesize\ =\ 200M/g" /etc/php/${PHP_VERSION}/apache2/php.ini
sudo sed -i "s/post_max_size\ =\ 8M/post_max_size\ =\ 200M/g" /etc/php/${PHP_VERSION}/apache2/php.ini
sudo sed -i "s/memory_limit\ =\ 128M/memory_limit\ =\ 500M/g" /etc/php/${PHP_VERSION}/apache2/php.ini
sudo sed -i "s/max_input_time.*/max_input_time = 360/" /etc/php/${PHP_VERSION}/apache2/php.ini
sudo sed -i "s/max_execution_time.*/max_execution_time = 5000/" /etc/php/${PHP_VERSION}/apache2/php.ini
sudo sed -i "s/^error_reporting.*/error_reporting = E_ERROR \& ~E_NOTICE \& ~E_STRICT \& ~E_DEPRECATED/" /etc/php/${PHP_VERSION}/apache2/php.ini
sudo sed -i "s/display_errors.*/display_errors = Off/" /etc/php/${PHP_VERSION}/apache2/php.ini
sudo sed -i "s/short_open_tag.*/short_open_tag = Off/" /etc/php/${PHP_VERSION}/apache2/php.ini
sudo sed -i "s/\;date\.timezone\ =/date\.timezone\ =\ Africa\/Kigali/g" /etc/php/${PHP_VERSION}/apache2/php.ini

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
wget https://suitecrm.com/download/165/suite88/565090/suitecrm-8-8-0.zip

mkdir /var/www/html/crm/
sudo unzip suitecrm-8-8-0.zip -d /var/www/html/crm/
rm suitecrm-8-8-0.zip

# Next, copy the extracted directory to the Apache web root and give proper permissions:
cd /var/www/html/crm/
sudo chown -R www-data:www-data .
sudo chmod -R 755 .
sudo chmod -R 775 cache custom modules themes data upload
sudo chmod 775 config_override.php 2>/dev/null

# Next, you will need to create an apache virtual host file for vTiger CRM. You can create it with the following command:
cat <<EOF > /etc/apache2/sites-available/suitecrm.conf

<VirtualHost *:80>
ServerName $WEBSITE_NAME
ServerAlias www.$WEBSITE_NAME
ServerAdmin admin@$WEBSITE_NAME
DocumentRoot /var/www/html/crm/

<Directory /var/www/html/crm/>
Options FollowSymLinks
AllowOverride All
Require all granted
</Directory>

ErrorLog /var/log/apache2/suitecrm-error.log
CustomLog /var/log/apache2/suitecrm-access.log common

</VirtualHost>
EOF

# Enable the Apache configuration for SuiteCRM and rewrite the module.
sudo a2ensite suitecrm.conf
sudo a2enmod rewrite
sudo systemctl restart apache2

# Configure firewall
sudo ufw allow OpenSSH
sudo ufw allow 'Apache Full'
sudo ufw enable

#--------------------------------------------------
# Enable ssl with certbot
#--------------------------------------------------

if [ $ENABLE_SSL = "True" ] && [ $ADMIN_EMAIL != "moodle@example.com" ]  && [ $WEBSITE_NAME != "example.com" ];then
  sudo apt install -y snapd
  sudo apt-get remove certbot
  
  sudo snap install core
  sudo snap refresh core
  sudo snap install --classic certbot
  sudo ln -s /snap/bin/certbot /usr/bin/certbot
  sudo certbot --apache -d $WEBSITE_NAME --noninteractive --agree-tos --email $ADMIN_EMAIL --redirect  
  echo "============ SSL/HTTPS is enabled! ========================"
else
  echo "==== SSL/HTTPS isn't enabled due to choice of the user or because of a misconfiguration! ======"
fi

sudo systemctl restart apache2

# Now, open your web browser and type the URL localhost on browser. 
echo "SuiteCRM has completed installation"
echo "https://yourdomain.com/crm/install.php"
