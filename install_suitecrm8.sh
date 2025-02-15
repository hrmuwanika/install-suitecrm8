#!/bin/sh
# Install SuiteCRM 8 on Ubuntu 24.04

# Variable
# Set to "True" to install certbot and have ssl enabled, "False" to use http
ENABLE_SSL="True"
# Set the website name
WEBSITE_NAME="example.com"
# Provide Email to register ssl certificate
ADMIN_EMAIL="moodle@example.com"

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

sudo apt install -y wget curl nano dirmngr gnupg2 lsb-release ubuntu-keyring unzip 

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

sudo apt install -y php8.3 php8.3-cli php8.3-common php8.3-curl php8.3-mbstring php8.3-gd php8.3-mysql php8.3-soap php-xml php8.3-imap php8.3-intl php8.3-tidy \
php8.3-zip php8.3-bcmath php8.3-redis libapache2-mod-php php8.3-ldap  

# Configure PHP
echo "Configuring PHP..."
sudo sed -i "s/upload_max_filesize\ =\ 2M/upload_max_filesize\ =\ 200M/g" /etc/php/8.3/apache2/php.ini
sudo sed -i "s/post_max_size\ =\ 8M/post_max_size\ =\ 200M/g" /etc/php/8.3/apache2/php.ini
sudo sed -i "s/memory_limit\ =\ 128M/memory_limit\ =\ 500M/g" /etc/php/8.3/apache2/php.ini
sudo sed -i "s/max_input_time.*/max_input_time = 360/" /etc/php/8.3/apache2/php.ini
sudo sed -i "s/max_execution_time.*/max_execution_time = 5000/" /etc/php/8.3/apache2/php.ini
sudo sed -i "s/\;date\.timezone\ =/date\.timezone\ =\ Africa\/Kigali/g" /etc/php/8.3/apache2/php.ini

sudo sed -i "s/upload_max_filesize\ =\ 2M/upload_max_filesize\ =\ 200M/g" /etc/php/8.3/cli/php.ini
sudo sed -i "s/post_max_size\ =\ 8M/post_max_size\ =\ 200M/g" /etc/php/8.3/cli/php.ini
sudo sed -i "s/memory_limit\ =\ 128M/memory_limit\ =\ 500M/g" /etc/php/8.3/cli/php.ini
sudo sed -i "s/max_input_time.*/max_input_time = 360/" /etc/php/8.3/cli/php.ini
sudo sed -i "s/max_execution_time.*/max_execution_time = 5000/" /etc/php/8.3/cli/php.ini
sudo sed -i "s/\;date\.timezone\ =/date\.timezone\ =\ Africa\/Kigali/g" /etc/php/8.3/cli/php.ini

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
cd /var/www/html/
wget https://suitecrm.com/download/165/suite88/565090/suitecrm-8-8-0.zip

sudo unzip suitecrm-8-8-0.zip -d /var/www/html
rm suitecrm-8-8-0.zip
sudo chown -R www-data:www-data /var/www/html

# Next, copy the extracted directory to the Apache web root and give proper permissions:
find . -type d -not -perm 2775 -exec chmod 2775 {} \;
find . -type f -not -perm 0664 -exec chmod 0664 {} \;
find . ! -user www-data -exec chown www-data:www-data {} \;
chmod +x bin/console

sudo -u www-data ./bin/console suitecrm:app:install -u "alice" -p "Password" -U "suitecrmuser" -P "m0d1fyth15" -H "127.0.0.1" -N "suitecrmdb" -S "http://crm.example.com/"

# Next, you will need to create an apache virtual host file for suite CRM. You can create it with the following command:
cat <<EOF > /etc/apache2/sites-available/suitecrm.conf

<VirtualHost *:80>
ServerName $WEBSITE_NAME
ServerAlias www.$WEBSITE_NAME
ServerAdmin admin@$WEBSITE_NAME
DocumentRoot /var/www/html/public

<Directory /var/www/html/public>
    AllowOverride All
    Order Allow,Deny
    Allow from All
</Directory>

ErrorLog ${APACHE_LOG_DIR}/error.log
CustomLog ${APACHE_LOG_DIR}/access.log combined

</VirtualHost>
EOF

# Enable the Apache configuration for SuiteCRM and rewrite the module.
#sudo a2enmod rewrite ssl header
sudo a2ensite suitecrm.conf

sudo apachectl configtest
sudo systemctl reload apache2

# Configure firewall
apt install -y ufw
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
echo "https://yourdomain.com/public/install.php"
