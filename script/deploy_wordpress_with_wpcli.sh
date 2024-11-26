#!/bin/bash

set -ex

source .env # Importamos el contenido de variables de entorno

# Eliminamos los archivos de WordPress de /tmp
rm -rf  /tmp/wp-cli.phar*

# Descargamos WordPress con la utilidad de Wp-Cli
wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -P /tmp

# Le asignamos permisos de ejecución
chmod +x /tmp/wp-cli.phar

# Renombramos la utilidad de Wp-Cli a wp
mv /tmp/wp-cli.phar /usr/local/bin/wp

# Elimino los archivos de WordPress para que posteriormente pueda 
rm -rf /var/www/html/*

# Descargamos el código fuente de WordPress
wp core download --locale=es_ES --path=/var/www/html --allow-root

# Creamos la base de datos para utilizarla con WordPress
mysql -u root <<< "DROP DATABASE IF EXISTS $WORDPRESS_DB_NAME"
mysql -u root <<< "CREATE DATABASE $WORDPRESS_DB_NAME"
mysql -u root <<< "DROP USER IF EXISTS $WORDPRESS_DB_USER@$IP_CLIENTE_MYSQL"
mysql -u root <<< "CREATE USER $WORDPRESS_DB_USER@$IP_CLIENTE_MYSQL IDENTIFIED BY '$WORDPRESS_DB_PASSWORD'"
mysql -u root <<< "GRANT ALL PRIVILEGES ON $WORDPRESS_DB_NAME.* TO $WORDPRESS_DB_USER@$IP_CLIENTE_MYSQL"

# Creamos el archivo de configuración
wp config create \
  --dbname=$WORDPRESS_DB_NAME \
  --dbuser=$WORDPRESS_DB_USER \
  --dbpass=$WORDPRESS_DB_PASSWORD \
  --dbhost=$WORDPRESS_DB_HOST \
  --path=/var/www/html \
  --allow-root

# Automatizamos la instalación de WordPress
wp core install \
  --url=$LE_DOMAIN \
  --title="$WORDPRESS_TITLE"\
  --admin_user=$WORDPRESS_ADMIN_USER \
  --admin_password=$WORDPRESS_ADMIN_PASSWORD \
  --admin_email=$WORDPRESS_ADMIN_EMAIL \
  --path=/var/www/html \
  --allow-root  

# Configuramos permalink
wp rewrite structure '/%postname%/' \
  --path=/var/www/html \
  --allow-root

# Copiamos el contenido de .htaccess a /var/www/html
cp ../htaccess/.htaccess /var/www/html

# Instalamos un tema y lo activamos
wp theme install mindscape --activate --path=/var/www/html --allow-root

# Instalamos un plugin y lo activamos
wp plugin install wps-hide-login --activate --path=/var/www/html --allow-root

# Configuramos el plugin
wp option update whl_page "$WHP_PAGE" --path=/var/www/html --allow-root

# Modificamos el propietario y el grupo de /var/www/html
chown -R www-data:www-data /var/www/html
