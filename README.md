## Nginx 

This repository contains **Dockerfile** of [Nginx](http://nginx.org/)
for [Docker](https://www.docker.com/)'s 
[automated build](https://registry.hub.docker.com/u/dockerfile/nginx/).

It's a simple and lightweight nginx image, based on the 
[official nginx image](https://github.com/nginxinc/docker-nginx/blob/8921999083def7ba43a06fabd5f80e4406651353/mainline/alpine/Dockerfile).

It just add a more complete default config file to  start the server.

### Usage

You can run a new instance of nginx using:

```
docker run -d --name nginx -p 80:80 mike325/nginx
```

or using docker-compose,
just create a `docker-compose.yml`

```yaml
version: '2'

services:
    nginx:
        image: mike325/nginx:latest
        restart: always
        container_name: nginx
        ports:
            - "80:80"
        volumes:
            - /etc/nginx/sites-enabled:/etc/nginx/sites-enabled
            - /etc/nginx/logs:/var/log/nginx
        networks:
            - reverse_proxy

networks:
    reverse_proxy:
        driver: bridge
```
and run `docker-compose up -d nginx`


#### Attach persistent/shared directories

You may also want to use your own virtual host or use certificates to
encrypt your sites:

```
docker run -d \
    --name nginx \
    -p 80:80 \
    -p 443:443 \
    -v <sites-enabled-dir>:/etc/nginx/sites-enabled \
    -v <certs-dir>:/etc/nginx/certs \
    -v <logs-dir>:/var/log/nginx \
    mike325/nginx
```

You can check the `example.conf` to configure the image to reverse proxy your sites.


### Manual build 

You can also build an image from the Dockerfile to modify the nginx.conf file:

```
git clone https://github.com/mike325/nginx

cd nginx

docker build -t custom_nginx .

docker run --name custom_nginx -p 80:80 custom_nginx

```

or with docker-compose using your `docker-compose.yml`:


```yaml
version: '2'

services:
    custom_nginx:
        build: .
        restart: always
        container_name: custom_nginx
        ports:
            - "80:80"
        volumes:
            - /etc/nginx/sites-enabled:/etc/nginx/sites-enabled
            - /etc/nginx/logs:/var/log/nginx
        networks:
            - reverse_proxy

networks:
    reverse_proxy:
        driver: bridge
```

and run `docker-compose up -d custom_nginx`
