#!/bin/bash
apt-get update
apt-get install -y apache2
sed -i -e 's/80/31555/' /etc/apache2/ports.conf
echo "DevOps mentor assignment 4 is functional" > /var/www/html/index.html
systemctl restart apache2