# 🛒 Tienda Online - Proyecto DevOps

Aplicación e-commerce full-stack con arquitectura de microservicios, implementación de Blue-Green deployment en Kubernetes y configuración con Docker.

## 📋 Descripción del Proyecto

Este proyecto es una tienda online completa que incluye:
- **Frontend**: Aplicación React con carrito de compras
- **Backend**: API REST con Node.js/Express y documentación Swagger
- **Base de Datos**: MySQL con datos de ejemplo
- **Infraestructura**: Kubernetes (Minikube) con estrategia Blue-Green deployment
- **Containerización**: Docker y Docker Compose

## 🏗️ Arquitectura

```
tienda-online/
├── frontend/           # React App (Puerto 3000/80)
├── backend/            # Node.js API (Puerto 5000)
├── database/           # MySQL + Esquema
├── k8s/                # Manifiestos Kubernetes
│   ├── apps/           # Deployments Blue-Green
│   └── mysql/          # StatefulSet MySQL
└── terraform/          # (En desarrollo)
```

## 🚀 Formas de Levantar el Proyecto

### **Opción 1: Desarrollo Local (Más Rápido para desarrollo)**

#### 1. Levantar la Base de Datos
```bash
cd database
docker-compose up -d
```
Esto levanta:
- MySQL en puerto 3306
- phpMyAdmin en http://localhost:8080

#### 2. Instalar Dependencias
```bash
# Desde la raíz del proyecto
npm run install-all
```

#### 3. Configurar Variables de Entorno
El archivo `backend/config.env` ya está configurado:
```env
DB_HOST=localhost
DB_PORT=3306
DB_USER=tienda_user
DB_PASSWORD=tienda_pass
DB_NAME=tienda_online
PORT=5000
```

#### 4. Iniciar el Backend
```bash
cd backend
npm start
# O para desarrollo con hot-reload:
npm run dev
```
El backend estará en: http://localhost:5000
API Docs (Swagger): http://localhost:5000/api-docs

#### 5. Iniciar el Frontend
```bash
cd frontend
npm start
```
El frontend estará en: http://localhost:3000

---

### **Opción 2: Docker Compose (Containerizado simple)**

```bash
# Levantar todos los servicios
docker-compose up -d --build

# Ver logs
docker-compose logs -f

# Detener servicios
docker-compose down
```

**Nota**: Necesitas un `docker-compose.yml` en la raíz (actualmente no está presente).

---

### **Opción 3: Kubernetes con Minikube (Producción-like con Blue-Green)**

Esta es la opción más completa que implementa Blue-Green deployment.

#### Prerequisitos
- Minikube instalado
- kubectl instalado
- Docker instalado

#### Pasos Detallados

**1. Iniciar Minikube**
```bash
minikube start
```

**2. Configurar Docker para usar el daemon de Minikube**
```bash
eval $(minikube docker-env)
```
⚠️ **Importante**: Este comando debe ejecutarse en cada terminal nueva.

**3. Construir las imágenes Docker**

**Versión Blue (Actual):**
```bash
# Construir frontend blue
docker build -t app-frontend:blue ./frontend

# Construir backend blue
docker build -t app-backend:blue ./backend
```

**Versión Green (Nueva):**
```bash
# Construir frontend green
docker build -t app-frontend:green ./frontend

# Construir backend green
docker build -t app-backend:green ./backend
```

💡 **Tip**: Para diferenciar las versiones, puedes modificar el archivo `frontend/src/components/Header.js` antes de cada build.

**4. Desplegar en Kubernetes**
```bash
# Crear namespace
kubectl apply -f k8s/namespace.yaml

# Desplegar MySQL
kubectl apply -f k8s/mysql/

# Esperar a que MySQL esté listo
kubectl wait --for=condition=ready pod -l app=mysql -n appdevops --timeout=300s

# Desplegar aplicaciones (Blue y Green)
kubectl apply -f k8s/apps/deployment-blue.yaml
kubectl apply -f k8s/apps/deployment-green.yaml
kubectl apply -f k8s/apps/service.yaml
```

**5. Verificar el despliegue**
```bash
# Ver todos los pods
kubectl get pods -n appdevops

# Ver servicios
kubectl get services -n appdevops
```

**6. Acceder a la aplicación**
```bash
# Abrir en el navegador
minikube service frontend-service -n appdevops

# O obtener la URL
minikube service frontend-service -n appdevops --url
```

#### 🔄 Blue-Green Deployment

**Cambiar de Blue a Green:**
```bash
kubectl patch service frontend-service -n appdevops -p '{"spec":{"selector":{"version":"green"}}}'
kubectl patch service backend-service -n appdevops -p '{"spec":{"selector":{"version":"green"}}}'
```

**Volver a Blue:**
```bash
kubectl patch service frontend-service -n appdevops -p '{"spec":{"selector":{"version":"blue"}}}'
kubectl patch service backend-service -n appdevops -p '{"spec":{"selector":{"version":"blue"}}}'
```

**Verificar versión activa:**
```bash
kubectl get service frontend-service -n appdevops -o jsonpath='{.spec.selector}'
```

---

## 📊 Endpoints de la API

Una vez levantado el backend, tienes disponible:

### Endpoints principales:
- `GET /` - Health check
- `GET /api` - Información de la API
- `GET /api/productos` - Lista de productos
- `GET /api/productos/:id` - Detalle de un producto
- `POST /api/pedidos` - Crear pedido

### Documentación Swagger:
- http://localhost:5000/api-docs (desarrollo local)
- http://<minikube-ip>:<nodeport>/api-docs (Kubernetes)

## 🗄️ Base de Datos

### Acceso directo a MySQL:
```bash
# Con Docker Compose
docker-compose exec mysql mysql -u tienda_user -ptienda_pass tienda_online

# En Kubernetes
kubectl exec -it mysql-0 -n appdevops -- mysql -u tienda_user -ptienda_pass tienda_online
```

### phpMyAdmin (solo en Docker Compose):
- URL: http://localhost:8080
- Usuario: `root`
- Password: `root123`

### Tablas incluidas:
- `productos` - 8 productos de ejemplo
- `pedidos` - Historial de pedidos
- `pedido_items` - Items de cada pedido
- `usuarios` - Usuarios (opcional)

## 🛠️ Comandos Útiles

### Docker
```bash
# Ver imágenes
docker images | grep app-

# Limpiar imágenes
docker rmi app-frontend:blue app-frontend:green app-backend:blue app-backend:green

# Ver logs del backend
docker-compose logs -f backend
```

### Kubernetes
```bash
# Ver logs de un pod
kubectl logs -f <pod-name> -n appdevops

# Ver logs de una versión específica
kubectl logs -l app=frontend,version=blue -n appdevops

# Describir un pod con problemas
kubectl describe pod <pod-name> -n appdevops

# Ejecutar comando en un pod
kubectl exec -it <pod-name> -n appdevops -- /bin/sh

# Ver eventos del namespace
kubectl get events -n appdevops --sort-by='.lastTimestamp'
```

### Limpieza
```bash
# Docker Compose
docker-compose down -v

# Kubernetes
kubectl delete namespace appdevops

# Minikube
minikube stop
minikube delete
```

## 🎯 Características del Proyecto

### Frontend (React)
- ✅ Carrito de compras funcional
- ✅ Listado de productos con filtros
- ✅ Detalle de producto
- ✅ Proceso de checkout
- ✅ Diseño responsive
- ✅ Indicador de versión (Blue/Green)

### Backend (Node.js/Express)
- ✅ API RESTful completa
- ✅ Documentación Swagger interactiva
- ✅ Validación de datos
- ✅ Manejo de errores
- ✅ CORS configurado
- ✅ Health checks

### DevOps
- ✅ Dockerfiles optimizados
- ✅ Multi-stage builds
- ✅ Health checks en containers
- ✅ Blue-Green deployment
- ✅ StatefulSet para MySQL
- ✅ Secrets y ConfigMaps
- ✅ Namespace aislado

## 🔧 Configuración Avanzada

### Variables de Entorno Backend
Archivo: `backend/config.env`
```env
DB_HOST=mysql-service
DB_PORT=3306
DB_USER=tienda_user
DB_PASSWORD=tienda_pass
DB_NAME=tienda_online
PORT=5000
NODE_ENV=production
CORS_ORIGIN=http://localhost:3000
```

### Proxy Frontend (desarrollo)
El frontend está configurado con proxy para el backend en `package.json`:
```json
"proxy": "http://localhost:5000"
```

## 📝 Estructura de Archivos Importante

```
backend/
├── index.js           # Servidor Express principal
├── swagger.js         # Configuración Swagger
├── config.env         # Variables de entorno
├── healthcheck.js     # Script health check
├── Dockerfile         # Imagen Docker backend
└── package.json       # Dependencias Node

frontend/
├── src/
│   ├── App.js         # Componente principal
│   └── components/    # Componentes React
├── Dockerfile         # Multi-stage build
├── nginx.conf         # Configuración Nginx
└── package.json       # Dependencias React

k8s/
├── namespace.yaml     # Namespace appdevops
├── apps/
│   ├── deployment-blue.yaml
│   ├── deployment-green.yaml
│   └── service.yaml
└── mysql/
    ├── statefulset.yaml
    ├── service.yaml
    ├── secret.yaml
    ├── config.yaml
    └── initdb-configmap.yaml
```

## 🐛 Troubleshooting

### "Cannot connect to database"
- Verifica que MySQL esté corriendo
- Revisa las credenciales en `config.env`
- En Kubernetes, espera a que el pod de MySQL esté Ready

### "Image not found" en Kubernetes
- Asegúrate de ejecutar `eval $(minikube docker-env)`
- Reconstruye las imágenes dentro del contexto de Minikube

### El frontend no carga productos
- Verifica que el backend esté corriendo
- Revisa CORS en `backend/index.js`
- Chequea la configuración del proxy

### Pods en estado CrashLoopBackOff
```bash
kubectl logs <pod-name> -n appdevops
kubectl describe pod <pod-name> -n appdevops
```

## 📚 Recursos Adicionales

- [Documentación Kubernetes](https://kubernetes.io/docs/)
- [Documentación Minikube](https://minikube.sigs.k8s.io/docs/)
- [Express.js](https://expressjs.com/)
- [React](https://react.dev/)
- [Swagger](https://swagger.io/)

## 👥 Autor

Proyecto de DevOps - UCU 2025

## 📄 Licencia

MIT

