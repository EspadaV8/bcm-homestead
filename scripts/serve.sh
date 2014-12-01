#!/usr/bin/env bash
if [ -f /etc/nginx/sites-enabled/vagrant ]
then
    rm /etc/nginx/sites-enabled/vagrant
fi
if [ -f /etc/apache2/sites-enabled/vagrant ]
then
    rm /etc/apache2/sites-enabled/vagrant
fi

block="server {
    listen 80;
    server_name $1;
    root $2;

    charset utf-8;
    client_max_body_size 10M;

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    sendfile off;

    location / {
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header Host \$http_host;
        proxy_set_header X-NginX-Proxy true;

        proxy_pass http://127.0.0.1:8001;
        proxy_redirect off;
    }
}

server {
    listen 443 ssl;
    server_name $1;
    root $2;

    charset utf-8;
    client_max_body_size 10M;

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    sendfile off;

    ssl_certificate         /etc/ssl/certs/ssl-cert-snakeoil.pem;
    ssl_certificate_key     /etc/ssl/private/ssl-cert-snakeoil.key;

    ssl_session_timeout 5m;
    ssl_protocols SSLv3 TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers 'ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:ECDHE-RSA-RC4-SHA:ECDHE-ECDSA-RC4-SHA:AES128:AES256:RC4-SHA:HIGH:!aNULL:!eNULL:!EXPORT:!DES:!3DES:!MD5:!PSK';
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:50m;

    location / {
        proxy_set_header X-Real-IP         \$remote_addr;
        proxy_set_header X-Forwarded-For   \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Host  \$http_host;
        proxy_set_header Host              \$http_host;
        proxy_set_header X-NginX-Proxy     true;
        proxy_set_header X-Forwarded-Proto https;
        add_header       Front-End-Https   on;

        proxy_pass       http://127.0.0.1:8001;
        proxy_redirect   off;
    }
}"

echo "$block" > "/etc/nginx/sites-available/$1"
ln -fs "/etc/nginx/sites-available/$1" "/etc/nginx/sites-enabled/$1"

block="<VirtualHost 127.0.0.1:8001>
    ServerName                  $1
    DocumentRoot                $2
    ErrorLog                    $3/error.log
    CustomLog                   $3/access.log combined
    php_admin_value error_log   $3/php.error.log

    <IfModule mpm_itk_module>
        AssignUserId vagrant vagrant
    </IfModule>

    <IfModule mod_expires.c>
        ExpiresActive On
        ExpiresByType image/gif \"access plus 1 months\"
        ExpiresByType image/jpg \"access plus 1 months\"
        ExpiresByType image/jpeg \"access plus 1 months\"
        ExpiresByType image/png \"access plus 1 months\"
        ExpiresByType image/vnd.microsoft.icon \"access plus 1 months\"
        ExpiresByType image/x-icon \"access plus 1 months\"
        ExpiresByType image/ico \"access plus 1 months\"
        ExpiresByType application/javascript \"now plus 1 months\"
        ExpiresByType application/x-javascript \"now plus 1 months\"
        ExpiresByType text/javascript \"now plus 1 months\"
        ExpiresByType text/css \"now plus 1 months\"
        ExpiresDefault \"access plus 1 days\"
    </IfModule>
</VirtualHost>"
echo "$block" > "/etc/apache2/sites-available/$1"
ln -fs "/etc/apache2/sites-available/$1" "/etc/apache2/sites-enabled/$1"
