FROM nginx:mainline-alpine
MAINTAINER Mike <mike@prodeveloper.me> 

ENV NGINX_VERSION 1.11.5
USER nginx

# Cache dir 
RUN mkdir -p /tmp/nginx/cache

#Add custom nginx config file.
COPY ./nginx.conf /etc/nginx/nginx.conf

# Define working directory.
WORKDIR /etc/nginx

# Define mountable directories.
VOLUME ["/etc/nginx/sites-enabled", "/etc/nginx/certs", "/etc/nginx/conf.d", "/var/log/nginx", "/var/www/"]

# Expose ports.
EXPOSE 80 443

# Define default command.
CMD ["nginx", "-g", "daemon off;"]
