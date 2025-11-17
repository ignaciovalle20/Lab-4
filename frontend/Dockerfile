# Frontend Dockerfile
FROM node:18.19.0-alpine3.18 AS build

# Establecer directorio de trabajo
WORKDIR /app

# Copiar archivos de configuración
COPY package*.json ./

# Instalar dependencias optimizado:
# - npm ci es más rápido y determinístico que npm install
# - --prefer-offline usa cache local cuando es posible
# - --no-audit evita verificación de seguridad (se hace en pipeline)
RUN npm ci --prefer-offline --no-audit && npm cache clean --force

# Copiar código fuente
COPY . .

# Construir la aplicación para producción
RUN npm run build

# Etapa de producción con nginx
FROM nginx:1.25.3-alpine

# Crear usuario no-root para nginx
RUN addgroup -g 1001 -S nginx-app && \
    adduser -S nginx-app -u 1001 -G nginx-app && \
    chown -R nginx-app:nginx-app /usr/share/nginx/html && \
    chown -R nginx-app:nginx-app /var/cache/nginx && \
    chown -R nginx-app:nginx-app /var/log/nginx && \
    touch /var/run/nginx.pid && \
    chown -R nginx-app:nginx-app /var/run/nginx.pid

# Copiar archivos construidos al directorio de nginx
COPY --from=build --chown=nginx-app:nginx-app /app/build /usr/share/nginx/html

# Copiar configuración personalizada de nginx
COPY --chown=nginx-app:nginx-app nginx.conf /etc/nginx/conf.d/default.conf

# Cambiar a usuario no-root
USER nginx-app

# Exponer puerto 8080 (no privilegiado)
EXPOSE 8080

# Comando por defecto
CMD ["nginx", "-g", "daemon off;"]
