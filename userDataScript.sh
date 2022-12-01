#!/bin/bash
apt-get update
apt-get install -y apache2
sed -i -e 's/80/8080/' /etc/apache2/ports.conf
echo "Hello World" > /var/www/html/index.html
systemctl restart apache2