# Desplegar WordPress mediante CLI

Esta practica es una continuación de la [practica 1.6](https://github.com/ArturoCarrilloJimenez/Practica-daw-1.6)

## Estructurara de carpetas

En primer lugar copiaremos los siguientes archivos del ejercicio anterior y crearemos los siguientes archivos: `deploy_wordpress_with_wpcl.sh`

```sh
├── conf/
│   └── 000-default.conf
├── htaccess/
│   └── .htaccess
├── php/
│   └── index.php
├── script/
│   ├── .env
│   ├── .env.ejemplo
│   ├── deploy_wordpress_own_directory.sh
│   ├── deploy_wordpress_root_directory.sh
│   ├── deploy_wordpress_with_wpcl.sh
│   ├── install_lamp.sh
│   └── setup_letsencrypt_https.sh
├── .gitignore
└── README.md
```

## Despliegue mediante WordPress Cli

Para comenzar pondremos la misma estructura inicial de todos los script, después de esto eliminaremos los archivos temporales para posteriormente descargar Wp-cli

``` sh
rm -rf  /tmp/wp-cli.phar*
```
### Descargar wordPress Cli

Comenzamos con la descarga de WordPress con la utilidad de Wp-Cli, esto se descargara en los archivos temporales

``` sh
wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -P /tmp
```

Para poder ejecutar WordPress cli debemos de darle permisos de ejecución mediante `chmod +x /tmp/wp-cli.phar`

Para ejecutarlo solo llamando al nombre debemos de moverlo a __/usr/local/bin/wp__, de esta forma llamamos a wp y no a la ruta

``` sh
mv /tmp/wp-cli.phar /usr/local/bin/wp
```

### Desplegar WordPress mediante cli

En primer lugar eliminaremos los archivos que se encuentren en __/var/www/html__ para que no aya conflicto al descargar el código fuente de WordPress

``` sh
rm -rf /var/www/html/*
```

Posteriormente descargaremos el código de este mediante eñl comando wp que emos descargado y configurado anteriormente

``` sh
wp core download --locale=es_ES --path=/var/www/html --allow-root
```

Para poder realizar la instalación de WordPress debemos de crear una base de datos con un usuario para esta,ademas debemos de añadir en el __.env__ las siguientes variables:
* WORDPRESS_DB_NAME
* WORDPRESS_DB_USER
* WORDPRESS_DB_PASSWORD
* IP_CLIENTE_MYSQL, este sera localhost


``` sh
mysql -u root <<< "DROP DATABASE IF EXISTS $WORDPRESS_DB_NAME"
mysql -u root <<< "CREATE DATABASE $WORDPRESS_DB_NAME"
mysql -u root <<< "DROP USER IF EXISTS $WORDPRESS_DB_USER@$IP_CLIENTE_MYSQL"
mysql -u root <<< "CREATE USER $WORDPRESS_DB_USER@$IP_CLIENTE_MYSQL IDENTIFIED BY '$WORDPRESS_DB_PASSWORD'"
mysql -u root <<< "GRANT ALL PRIVILEGES ON $WORDPRESS_DB_NAME.* TO $WORDPRESS_DB_USER@$IP_CLIENTE_MYSQL"
```

Una vez que creamos la base de datos, configuramos WordPress mediante __wp__ de la siguiente forma, para esto necesitaremos añadir en el __.env__ la siguiente variable:
* WORDPRESS_DB_HOST, que sera localhost

``` sh
wp config create \
  --dbname=$WORDPRESS_DB_NAME \
  --dbuser=$WORDPRESS_DB_USER \
  --dbpass=$WORDPRESS_DB_PASSWORD \
  --dbhost=$WORDPRESS_DB_HOST \
  --path=/var/www/html \
  --allow-root
```

Para automatizar la instalación de WordPress utilizaremos el comando __wp__, aquí configuraremos los datos de el administrador de este, el titulo entre otras cosas.

Antes de añadir este comando añadiremos al __.env__ las siguientes variables:
* LE_DOMAIN, este lo debemos de tener anteriormente ya que lo emos utilizado para Les`t Encrypt
* WORDPRESS_TITLE
* WORDPRESS_ADMIN_USER
* WORDPRESS_ADMIN_PASSWORD
* WORDPRESS_ADMIN_EMAIL

``` sh
wp core install \
  --url=$LE_DOMAIN \
  --title="$WORDPRESS_TITLE"\
  --admin_user=$WORDPRESS_ADMIN_USER \
  --admin_password=$WORDPRESS_ADMIN_PASSWORD \
  --admin_email=$WORDPRESS_ADMIN_EMAIL \
  --path=/var/www/html \
  --allow-root  
```

Con esto ya podemos entrar a nuestro dominio y nos aparecerá una pagina de ejemplo de WordPress

### Configuración del permalink

Este es una forma de apuntar al contenido de una web, con esto aremos que con el nombre de la pagina nos redirection al archivo deseado, de esta forma mejora el SEO entre otras cosas

En primer lugar reescribiremos la estructura de este para que ocurra la redirection

``` sh
wp rewrite structure '/%postname%/' \
  --path=/var/www/html \
  --allow-root
```

Posteriormente debemos de configurar el archivo __.htaccess__ para que ocurra la redirection de forma correcta, sin esto no sera posible redirection a la pagina correcta

```
# BEGIN WordPress
<IfModule mod_rewrite.c>
RewriteEngine On
RewriteBase /
RewriteRule ^index\.php$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.php [L]
</IfModule>
# END WordPress
```

Ademas debemos de copiar este archivo en __/var/www/html__

``` sh
cp ../htaccess/.htaccess /var/www/html
```

### Configuración y personalización de WordPress

Para esto instaremos un tema y un plugin y lo activaremos

El tema que instalaremos es mindscape, esto lo lograremos con el siguiente comando 

``` sh
wp theme install mindscape --activate --path=/var/www/html --allow-root
```

Ademas instalaremos un plugin llamado __wps-hide-login__ que nos permite ocultar la ruta de administración cambiándola de nombre, ya que por defecto es /__wp-admin__

``` sh
wp plugin install wps-hide-login --activate --path=/var/www/html --allow-root
```

Ademas debemos de configurar la ruta que queremos que sea de administrador, esto lo lograremos mediante el siguiente comando, para que este funcione debemos de añadir en el ``.env`` la variable ``WHP_PAGE`` que sera el nuevo nombre de la ruta de administración

``` sh
wp option update whl_page "$WHP_PAGE" --path=/var/www/html --allow-root
```

### Cambiar el propietario de WordPress

Debemos de cambiar e propietario de WordPress ya que si no, cada vez que queramos modificar algo, instalar o activar algo nos pedirá el usuario root

``` sh
chown -R www-data:www-data /var/www/html
```