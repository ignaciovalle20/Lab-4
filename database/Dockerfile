# Database Dockerfile - Optimizado para Lab 4
FROM mysql:8.0.35

# Variables de entorno para MySQL
ENV MYSQL_DATABASE=tienda_online
ENV MYSQL_ROOT_PASSWORD=root123
ENV MYSQL_USER=tienda_user
ENV MYSQL_PASSWORD=tienda_pass

# Copiar el script de inicialización
COPY schema.sql /docker-entrypoint-initdb.d/

# Configurar MySQL
COPY my.cnf /etc/mysql/conf.d/

# Exponer puerto MySQL
EXPOSE 3306

# Configurar volumen para persistencia de datos
VOLUME ["/var/lib/mysql"]

# Nota: MySQL requiere ejecutarse como usuario mysql por defecto
# El contenedor ya viene configurado con este usuario no-root
