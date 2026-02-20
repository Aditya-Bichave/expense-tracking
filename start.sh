#!/bin/sh
# Use PORT environment variable or default to 80
PORT="${PORT:-80}"
echo "Updating Nginx to listen on port $PORT..."
sed -i "s/listen 80;/listen $PORT;/g" /etc/nginx/conf.d/default.conf
nginx -g "daemon off;"
