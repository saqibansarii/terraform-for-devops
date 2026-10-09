#!/bin/bash


sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install nginx -y
sudo systemctl start nginx
sudo systemctl enable nginx 


echo "<h1>Terraform learning</h1>" |sudo tee /var/www/html/index.html
echo "<h2>Nginx is already install through script</h2>" |sudo tee -a /var/www/html/index.html