#!/bin/bash
sudo yum update -y
sudo amazon-linux-extras install nginx1 -y
sudo systemctl start nginx
sudo systemctl enable nginx
echo "<h1>AOA World from $(hostname -f)</h1>" > /usr/share/nginx/html/index.html
sudo chown nginx:nginx /usr/share/nginx/html/index.html
sudo systemctl restart nginx