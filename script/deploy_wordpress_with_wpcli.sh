#!/bin/bash

set -ex

source .env # Inportamos el contenido de variables de entorno

# Eliminamos los archivos de Wordpress de /tmp
rm -rf  /tmp/wp-cli.phar*

# Descargamos wordpres con la utilidad de Wp-Cli
wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -P /tmp

# Le asignamos permisos de ejecucion
chmod +x /tmp/wp-cli.phar

# Renombramos la utilidad de Wp-Cli a wp
mv /tmp/wp-cli.phar /usr/local/bin/wp

# Elimino los archivos de Wordpres para que posteriormente pueda 
rm -rf /var/www/html/*

# Descargamos el codigo fuente de wordpres
wp core download --locale=es_ES --path=/var/www/html --allow-root

# Creamos la base de datos para utilizarla con Wordpress
mysql -u root <<< "DROP DATABASE IF EXISTS $WORDPRESS_DB_NAME"
mysql -u root <<< "CREATE DATABASE $WORDPRESS_DB_NAME"
mysql -u root <<< "DROP USER IF EXISTS $WORDPRESS_DB_USER@$IP_CLIENTE_MYSQL"
mysql -u root <<< "CREATE USER $WORDPRESS_DB_USER@$IP_CLIENTE_MYSQL IDENTIFIED BY '$WORDPRESS_DB_PASSWORD'"
mysql -u root <<< "GRANT ALL PRIVILEGES ON $WORDPRESS_DB_NAME.* TO $WORDPRESS_DB_USER@$IP_CLIENTE_MYSQL"

# Creamos el archivo de configuracion
wp config create \
  --dbname=$WORDPRESS_DB_NAME \
  --dbuser=$WORDPRESS_DB_USER \
  --dbpass=$WORDPRESS_DB_PASSWORD \
  --dbhost=$WORDPRESS_DB_HOST \
  --path=/var/www/html \
  --allow-root

# Automatizamos la instalacion de WordPress
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

# Copiamos el contenido de .htacces a /var/www/html
cp ../htaccess/.htaccess /var/www/html

# Instalamos un tema y lo activamos
wp theme install mindscape --activate --path=/var/www/html --allow-root

# Instlamos un plugin y lo activamos
wp plugin install wps-hide-login --activate --path=/var/www/html --allow-root

# Configuramos el plagin
wp option update whl_page "$WHP_PAGE" --path=/var/www/html --allow-root

# Modificamos el propoietario y el grupo de /var/www/html
chown -R www-data:www-data /var/www/html
