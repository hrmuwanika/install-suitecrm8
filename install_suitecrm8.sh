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

# Install PHP8.3
sudo apt install ca-certificates apt-transport-https software-properties-common -y
sudo add-apt-repository ppa:ondrej/php  -y
sudo apt update

sudo apt install -y wget curl nano software-properties-common dirmngr apt-transport-https gnupg2 ca-certificates lsb-release ubuntu-keyring unzip 

# Install Apache Server
sudo apt install apache2 -y

# start Apache service
sudo systemctl enable apache2 
sudo systemctl start apache2

# Install mariadb databases
sudo apt install mariadb-server mariadb-client -y

# Secure Mariadb database
# sudo mariadb_secure_installation

# start MariaDB service 
sudo systemctl start mariadb 
sudo systemctl enable mariadb

sudo apt install -y php php-cli php-bcmath php-common php-imap php-redis php-snmp php-xml php-zip php-mbstring php-curl \
libapache2-mod-php php-gd php-intl php-mysql php-gd php-soap php-ldap php-imagick php-json php-bz2 php-gmp 



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
echo "Installing suitecrm ..."
cd /usr/src/
wget https://suitecrm.com/download/165/suite88/565090/suitecrm-8-8-0.zip

sudo unzip suitecrm-8-8-0.zip -d /var/www/html/
rm suitecrm-8-8-0.zip

# Next, copy the extracted directory to the Apache web root and give proper permissions:
cd /var/www/html/
sudo chown -R www-data:www-data /var/www/html/
sudo chmod -R 755 /var/www/html/
#sudo chmod -R 775 cache custom modules themes data upload
#sudo chmod 775 config_override.php 2>/dev/null

# Next, you will need to create an apache virtual host file for vTiger CRM. You can create it with the following command:
cat <<EOF > /etc/apache2/sites-available/suitecrm.conf

<VirtualHost *:80>
ServerName $WEBSITE_NAME
ServerAlias www.$WEBSITE_NAME
ServerAdmin admin@$WEBSITE_NAME
DocumentRoot /var/www/html/public/

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
sudo systemctl reload apache2

# Configure firewall
apt install -y ufw
sudo ufw allow OpenSSH
sudo ufw allow http
sudo ufw allow https
sudo ufw enable -y

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
echo "https://yourdomain.com/public/install.php"
