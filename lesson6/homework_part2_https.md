# /etc/nginx/sites-available/webbooks
```
  GNU nano 4.8                                                                          /etc/nginx/sites-available/webbooks
server {
    listen 80;
    server_name 192.168.1.107;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name _;

    ssl_certificate /etc/nginx/server.pem;
    ssl_certificate_key /etc/nginx/server.key;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Port $server_port;
    }

    location = /favicon.ico {
        log_not_found off;
        access_log off;
    }
}
```

# Сертификаты 
```
nikita@nikita:~$ ll /etc/nginx/ | grep server*
-rw-------   1 root root 1704 авг 14 21:53 server.key
-rw-r--r--   1 root root 1294 авг 14 21:53 server.pem
```