# Vtiger CRM Setup if need setup Contact Skype: linuxbiekaisar
# You Tube : https://www.youtube.com/watch?v=fR5tffoFQyY&t=2s

apt-get update -y
apt-get upgrade -y

# Install LAMP Server
apt-get install apache2 mariadb-server libapache2-mod-php7.2 php7.2 php7.2-cli php7.2-mysql php7.2-common php7.2-zip php7.2-mbstring php7.2-xmlrpc php7.2-curl php7.2-soap php7.2-gd php7.2-xml php7.2-intl php7.2-ldap php7.2-imap unzip wget -y

# After installing all the packages, open php.ini file, and make some changes, close the file, and save  it:

# file_uploads = On
# allow_url_fopen = On
# memory_limit = 256M
#upload_max_filesize = 30M
# post_max_size = 40M
# max_execution_time = 60
# max_input_vars = 1500

# start Apache and MariaDB service and enable them to start on boot time with the following command:

systemctl start apache2
systemctl start mariadb
systemctl enable apache2
systemctl enable mariadb

# By default, MariaDB is not secured. So, you will need to secure it. You can do this by running the mysql_secure_installation script:
mysql_secure_installation

# This script will change your current root password, remove anonymous users, disallow root login remotely as shown below:

# Enter current password for root (enter for none):
# Set root password? [Y/n]: N
# Remove anonymous users? [Y/n]: Y
# Disallow root login remotely? [Y/n]: Y
# Remove test database and access to it? [Y/n]:  Y
# Reload privilege tables now? [Y/n]:  Y

# After that login to Mariadb Shell: 
mysql -u root -p

# Create database and user:

MariaDB [(none)]> CREATE DATABASE vtigerdb;
MariaDB [(none)]> CREATE USER 'vtiger'@'localhost' IDENTIFIED BY 'password';
MariaDB [(none)]> GRANT ALL PRIVILEGES ON vtigerdb.* TO 'vtiger'@'localhost' IDENTIFIED BY 'mypassword' WITH GRANT OPTION;
MariaDB [(none)]> ALTER DATABASE vtigerdb CHARACTER SET utf8 COLLATE utf8_general_ci;
MariaDB [(none)]> FLUSH PRIVILEGES;
MariaDB [(none)]> exit

# Install vTiger CRM
wget https://excellmedia.dl.sourceforge.net/project/vtigercrm/vtiger%20CRM%207.1.0/Core%20Product/vtigercrm7.1.0.tar.gz

# Extract the downloaded file
tar -xvzf vtigercrm7.1.0.tar.gz

# Next, copy the extracted directory to the Apache web root and give proper permissions:
cp -r vtigercrm /var/www/html/
chown -R www-data:www-data /var/www/html/vtigercrm
chmod -R 755 /var/www/html/vtigercrm

# Next, you will need to create an apache virtual host file for vTiger CRM. You can create it with the following command:
nano /etc/apache2/sites-available/vtigercrm.conf

# Add the following lines:
#<VirtualHost *:80>
#     ServerAdmin admin@example.com
#     ServerName example.com
#     DocumentRoot /var/www/html/vtigercrm/

#     <Directory /var/www/html/vtigercrm/>
#     Options FollowSymlinks
#     AllowOverride All
#     Require all granted
#    </Directory>
#
#     ErrorLog /var/log/apache2/vtigercrm_error.log
#     CustomLog /var/log/apache2/vtigercrm_access.log combined
# </VirtualHost>

# Run the following command:
a2ensite vtigercrm
a2dissite 000-default
a2enmod rewrite
systemctl restart apache2
systemctl status apache2

# Now, open your web browser and type the URL localhost on browserm. 
# Click on the Install button. 
# accept the vTiger public licence. 
# verify installation prerequisites and click on the Next button.
# Next, provide your database name, database username, password, admin username and password. Then, click on the Next button.
# Next, select your industry and click on the Next button.
# 
