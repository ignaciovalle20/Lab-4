# 🛒 Tienda Online - Laboratorio 4: DevOps & DevSecOps

Aplicación e-commerce full-stack con arquitectura de microservicios, implementación completa de DevOps y DevSecOps, incluyendo CI/CD, monitoring, políticas de seguridad y runtime protection.

---

## 📋 Tabla de Contenidos

- [Descripción del Proyecto](#-descripción-del-proyecto)
- [Arquitectura](#%EF%B8%8F-arquitectura)
- [Tecnologías Utilizadas](#-tecnologías-utilizadas)
- [Características Implementadas](#-características-implementadas)
- [Inicio Rápido](#-inicio-rápido)
- [Guía de Instalación Detallada](#-guía-de-instalación-detallada)
- [Pipeline CI/CD](#-pipeline-cicd)
- [Monitoring y Observabilidad](#-monitoring-y-observabilidad)
- [Seguridad](#-seguridad)
- [Scripts de Automatización](#-scripts-de-automatización)
- [Troubleshooting](#-troubleshooting)
- [Mejoras Futuras](#-mejoras-futuras)
- [Referencias](#-referencias)

---

## 📋 Descripción del Proyecto

Este proyecto es una implementación completa de DevOps y DevSecOps para una tienda online, desarrollado como parte del Laboratorio 4. Incluye:

### Componentes de la Aplicación
- **Frontend**: React 18 con React Router para SPA
- **Backend**: Node.js/Express con API REST documentada (Swagger)
- **Base de Datos**: MySQL 8.0 con datos de ejemplo

### Infraestructura y DevOps
- **Containerización**: Docker con multi-stage builds, usuarios no-root
- **Orquestación**: Kubernetes (Minikube) con Helm Charts
- **CI/CD**: Jenkins con pipeline automatizado
- **Monitoring**: Prometheus + Grafana con métricas personalizadas
- **Security**: Kyverno (políticas), Falco (runtime), Semgrep (SAST), Snyk/Trivy (vulnerability scanning)

---

## 🏗️ Arquitectura

### Diagrama General

<img width="611" height="701" alt="Image" src="https://github.com/user-attachments/assets/179eae32-020a-4ef4-b957-4b67c575659a" />


### Flujo de Datos

1. **Usuario** → Accede al frontend a través del Ingress
2. **Frontend** → Hace requests al backend via API REST
3. **Backend** → Consulta/modifica datos en MySQL
4. **Prometheus** → Scraping de métricas del backend cada 15s
5. **Grafana** → Visualiza métricas de Prometheus
6. **Kyverno** → Valida recursos antes de admitirlos al cluster
7. **Falco** → Monitorea comportamiento en runtime

---

## 🛠️ Tecnologías Utilizadas

### Aplicación
| Componente | Tecnología | Versión |
|------------|-----------|---------|
| Frontend | React | 18.3.1 |
| Frontend Server | Nginx | 1.25.3-alpine |
| Backend | Node.js | 18.19.0-alpine3.18 |
| Backend Framework | Express | 4.21.2 |
| Database | MySQL | 8.0.35 |
| API Docs | Swagger | 5.0.0 |

### DevOps & Infraestructura
| Herramienta | Propósito | Versión |
|-------------|-----------|---------|
| Docker | Containerización | Latest |
| Kubernetes | Orquestación | 1.28+ (Minikube) |
| Helm | Package Manager | 3.x |
| Jenkins | CI/CD | Latest |

### Monitoring & Observability
| Herramienta | Propósito | Versión |
|-------------|-----------|---------|
| Prometheus | Metrics Collection | 2.x |
| Grafana | Visualization | 10.x |
| prom-client | Node.js metrics | 15.1.0 |

### Security & DevSecOps
| Herramienta | Propósito | Tipo |
|-------------|-----------|------|
| Kyverno | Policy Engine | Admission Control |
| Falco | Runtime Security | IDS |
| Semgrep | Static Analysis | SAST |
| Snyk | Dependency Scan | SCA |
| Trivy | Image Scanning | Vulnerability Scanner |

---

## ✨ Características Implementadas

### 1. Containerización Optimizada
- Multi-stage builds para reducir tamaño de imágenes
- Usuarios no-root en todos los contenedores
- Versiones específicas (no `latest`)
- `.dockerignore` para optimizar build context
- Health checks configurados
- Imágenes analizadas con Trivy
- Frontend: 45.4 MB (optimizado)

### 2. Orquestación con Kubernetes
- Helm Chart completo con templates
- Values para dev y prod
- Deployments con replicas configurables
- StatefulSet para MySQL con persistencia
- Services (ClusterIP y Headless)
- ConfigMaps y Secrets
- Ingress con routing
- Resource limits y requests
- Liveness y readiness probes

### 3. Monitoring & Observability
- Prometheus instalado con kube-prometheus-stack
- Backend instrumentado con prom-client
- Métricas personalizadas:
  - HTTP request duration (histogram)
  - HTTP request total (counter)
  - DB connection errors (counter)
  - Pedidos creados (counter)
  - Productos consultados (counter)
  - DB query duration (histogram)
- ServiceMonitor configurado
- Dashboard de Grafana con 9 paneles
- Métricas exportadas en `/metrics`

### 4. CI/CD con Jenkins
- Jenkins dockerizado con todas las herramientas
- Jenkinsfile con 8 stages:
  1. Clone
  2. Static Analysis (Semgrep)
  3. Dependency Scan (Snyk)
  4. Build
  5. Test
  6. Docker Build
  7. Docker Push
  8. Deploy (Helm)
- Plugins necesarios instalados
- Script de inicio automatizado
- Configuración as code

### 5. DevSecOps 
#### Static Analysis - Semgrep
- Análisis de backend y frontend
- 417 reglas ejecutadas
- 3 findings documentados
- Reporte detallado con recomendaciones
- Vulnerabilidad CSRF identificada

#### Dependency Scanning - Snyk
- Escaneo de dependencias de Node.js
- Reporte consolidado
- Vulnerabilidades categorizadas por severidad
- Recomendaciones de remediación

#### Image Scanning - Trivy
- 3 imágenes analizadas
- Reporte completo con CVEs
- Backend: 4 HIGH
- Frontend: 3 CRITICAL, 18 HIGH
- Database: 3 CRITICAL, 73 HIGH

#### Policy Engine - Kyverno
- 4 políticas implementadas:
  1. Disallow Latest Tag (MEDIUM)
  2. Require Resource Limits (MEDIUM)
  3. Disallow Root User (HIGH)
  4. Require Labels (LOW)
- Todas las políticas validadas
- Helm Chart cumple con todas las políticas
- Reporte de validación completo

#### Runtime Security - Falco
- Instalado con modern_ebpf driver
- 237 reglas cargadas
- 10 reglas personalizadas
- Eventos detectados y documentados:
  - Read sensitive file (/etc/shadow)
  - Shell spawned in container
  - Terminal shell in container
  - Unexpected program executed
- Reporte de evento completo

### 6. Automatización
- `init.sh` - Inicialización completa del proyecto
- `populate.sh` - Poblar DB con datos de prueba
- `cleanup.sh` - Limpieza completa de recursos
- `jenkins-start.sh` - Iniciar Jenkins
- `generate-traffic.sh` - Generar tráfico para métricas

### 7. Documentación
- README principal (este archivo)
- TODO.md con progreso detallado
- READMEs por componente:
  - k8s/monitoring/README.md
  - k8s/kyverno/README.md
  - k8s/falco/README.md
  - jenkins/README.md
- Reportes de seguridad:
  - reports/image-analysis.md
  - reports/semgrep-report.txt
  - reports/snyk-report.txt
  - reports/kyverno-validation.log
  - reports/falco-event.log

---

## 🚀 Inicio Rápido

### Prerequisitos

- Docker
- Minikube
- kubectl
- Helm 3+
- (Opcional) Jenkins para CI/CD

### Instalación Automática

```bash
# 1. Clonar el repositorio
git clone https://github.com/ignaciovalle20/Lab-4.git
cd Lab-4

# 2. Ejecutar script de inicialización
./scripts/init.sh

# 3. Poblar base de datos
./scripts/populate.sh

# 4. Acceder a los servicios
# Sigue las instrucciones que muestra el script init.sh
```

¡Eso es todo! En ~10 minutos tendrás todo desplegado.

---

## 📖 Guía de Instalación Detallada

### 1. Iniciar Minikube

```bash
minikube start
```

### 2. Construir Imágenes Docker

```bash
# Configurar Docker para usar el daemon de Minikube
eval $(minikube docker-env)

# Backend
docker build -t tienda-backend:lab4 ./backend

# Frontend
docker build -t tienda-frontend:lab4 ./frontend

# Database
docker build -t tienda-database:lab4 ./database
```

### 3. Crear Namespaces

```bash
kubectl create namespace tienda-online
kubectl create namespace monitoring
kubectl create namespace kyverno
kubectl create namespace falco
```

### 4. Instalar Prometheus y Grafana

```bash
# Crear ConfigMap de Grafana dashboards (requerido antes de instalar)
kubectl apply -f k8s/monitoring/grafana-dashboard-configmap.yaml

# Agregar repositorio de Helm
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Instalar Prometheus y Grafana
helm install prometheus prometheus-community/kube-prometheus-stack \
  -n monitoring \
  -f k8s/monitoring/prometheus-values.yaml \
  --wait --timeout=5m
```

### 5. Instalar Kyverno

```bash
helm repo add kyverno https://kyverno.github.io/kyverno/
helm repo update

helm install kyverno kyverno/kyverno -n kyverno

# Aplicar políticas
kubectl apply -f k8s/kyverno/
```

### 6. Instalar Falco

```bash
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm repo update

helm install falco falcosecurity/falco \
  -n falco \
  --set tty=true \
  --set driver.kind=modern_ebpf \
  --set falco.json_output=true
```

### 7. Desplegar Aplicación

```bash
helm install tienda-online ./helm-chart/tienda-online \
  -n tienda-online \
  -f helm-chart/tienda-online/values-dev.yaml
```

### 8. Aplicar ServiceMonitor

```bash
kubectl apply -f k8s/monitoring/servicemonitor.yaml
```

### 9. Verificar Despliegue

```bash
kubectl get pods -n tienda-online
kubectl get svc -n tienda-online
```

---

## 🔄 Pipeline CI/CD

### Arquitectura del Pipeline

```
┌──────────┐    ┌───────────┐    ┌───────────┐    ┌───────────┐
│  GitHub  │───▶│  Jenkins  │───▶│  Docker   │───▶│Kubernetes │
│   Push   │    │  Trigger  │    │   Build   │    │  Deploy   │
└──────────┘    └───────────┘    └───────────┘    └───────────┘
                      │
                      ▼
                ┌───────────┐
                │  Security │
                │  Scanning │
                └───────────┘
```

### Stages del Pipeline

1. **Clone**: Clonar repositorio de Git
2. **Semgrep**: Análisis estático de código
   - Backend: 213 reglas
   - Frontend: 204 reglas
3. **Snyk**: Escaneo de dependencias
   - npm audit + Snyk API
4. **Build**: Compilar aplicación
   - Backend: `npm install`
   - Frontend: `npm run build`
5. **Test**: Ejecutar tests (si existen)
6. **Docker Build**: Construir imágenes
   - Tags: `lab4`, `latest`, `$BUILD_NUMBER`
7. **Docker Push**: Publicar a registry
8. **Deploy**: Desplegar con Helm
   - Environment: dev/prod
   - Rolling update

### Configuración de Jenkins

```bash
# Iniciar Jenkins
./scripts/jenkins-start.sh

# Acceder
URL: http://localhost:8080
Usuario: admin
Password: admin123
```

Ver `jenkins/README.md` para configuración detallada.

---

## 📊 Monitoring y Observabilidad

### Acceso a Grafana

```bash
# Port forward
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# Acceder en navegador
open http://localhost:3000

# Credenciales
Usuario: admin
Password: admin123
```

### Dashboard de Grafana

El dashboard se carga automáticamente desde el ConfigMap `grafana-dashboards` al instalar Prometheus. El dashboard incluye 9 paneles:

1. **HTTP Requests per Second (RPS)**
   - Tasa de requests HTTP
   - Desglosado por método, ruta y código de estado

2. **HTTP Request Latency**
   - Latencia de requests (p50, p95, p99)
   - Útil para detectar problemas de performance

3. **CPU Usage**
   - Uso de CPU del proceso Node.js
   - Ayuda a identificar picos de procesamiento

4. **Memory Usage**
   - Memoria RSS, Heap Used y Heap Total
   - Detección de memory leaks

5. **Total Pedidos Creados**
   - Contador de pedidos (métrica de negocio)
   - Gauge con total acumulado

6. **Tasa de Creación de Pedidos**
   - Pedidos por segundo
   - Monitoreo de actividad de negocio

7. **Total Productos Consultados**
   - Contador de consultas a productos
   - Métrica de uso del catálogo

8. **Errores de Conexión a BD**
   - Errores de conexión a MySQL
   - Crítico para detectar problemas de infraestructura

9. **Database Query Latency**
   - Latencia de queries (p95)
   - Optimización de consultas

### Métricas Disponibles

```
# Métricas HTTP
tienda_online_http_requests_total
tienda_online_http_request_duration_seconds

# Métricas de Base de Datos
tienda_online_db_connection_errors_total
tienda_online_db_query_duration_seconds

# Métricas de Negocio
tienda_online_pedidos_creados_total
tienda_online_productos_consultados_total

# Métricas del Sistema (automáticas)
tienda_online_process_cpu_seconds_total
tienda_online_process_resident_memory_bytes
tienda_online_nodejs_heap_size_used_bytes
tienda_online_nodejs_heap_size_total_bytes
```

### Generar Tráfico para Testing

```bash
./scripts/generate-traffic.sh
```

---

## 🔒 Seguridad

### Análisis de Vulnerabilidades

#### Imágenes Docker

| Imagen | CRITICAL | HIGH | MEDIUM | LOW |
|--------|----------|------|--------|-----|
| Backend | 0 | 4 | - | - |
| Frontend | 3 | 18 | - | - |
| Database | 3 | 73 | - | - |

Ver `reports/image-analysis.md` para detalles.

#### Código Fuente (Semgrep)

- **Total findings**: 3 (Backend)
- **Severidad**: 3 MEDIUM
- **Principal issue**: Falta middleware CSRF
- Ver `reports/semgrep-report.txt`

#### Dependencias (Snyk)

- **Backend**: ~150-200 dependencias
- **Frontend**: ~1500 dependencias
- **Recomendación**: Ejecutar `npm audit fix`
- Ver `reports/snyk-report.txt`

### Políticas de Kyverno

4 políticas implementadas y validadas:

1. **disallow-latest-tag** (MEDIUM)
   - Bloquea imágenes con tag `latest`
   - Requiere versión específica

2. **require-resource-limits** (MEDIUM)
   - Requiere requests y limits de CPU/memoria
   - Previene OOM y throttling
   - **Excluye**: namespaces del sistema (`monitoring`, `kube-system`, `kyverno`, `falco`) y Jobs

3. **disallow-root-user** (HIGH)
   - Prohíbe ejecución como root
   - Requiere `runAsNonRoot: true`
   - **Excluye**: namespaces del sistema (`monitoring`, `kube-system`, `kyverno`, `falco`) y Jobs

4. **require-labels** (LOW)
   - Requiere etiquetas estándar de K8s
   - Facilita gestión y monitoreo

**Nota**: Las políticas `require-resource-limits` y `disallow-root-user` excluyen namespaces del sistema y Jobs para permitir la instalación de componentes de infraestructura como Prometheus y sus Helm hooks.

Ver `reports/kyverno-validation.log` para detalles.

### Runtime Security (Falco)

Eventos detectados durante testing:

- Read sensitive file untrusted (`/etc/shadow`)
-  Shell spawned in container
-  Terminal shell in container
-  Unexpected program executed

Ver `reports/falco-event.log` para detalles.

---

## 🤖 Scripts de Automatización

| Script | Propósito | Uso |
|--------|-----------|-----|
| `init.sh` | Inicialización completa del proyecto | `./scripts/init.sh` |
| `populate.sh` | Poblar DB con datos de prueba | `./scripts/populate.sh` |
| `cleanup.sh` | Limpieza completa de recursos | `./scripts/cleanup.sh` |
| `jenkins-start.sh` | Iniciar Jenkins | `./scripts/jenkins-start.sh` |
| `generate-traffic.sh` | Generar tráfico para métricas | `./scripts/generate-traffic.sh` |

### Ejemplo de Uso

```bash
# Despliegue completo desde cero
./scripts/init.sh

# Poblar base de datos
./scripts/populate.sh

# Generar métricas
./scripts/generate-traffic.sh

# Limpiar todo
./scripts/cleanup.sh
```

---

## 🐛 Troubleshooting

### Problema: Pods no inician

```bash
# Ver logs del pod
kubectl logs -n tienda-online <pod-name>

# Ver eventos
kubectl get events -n tienda-online --sort-by='.lastTimestamp'

# Describir pod
kubectl describe pod -n tienda-online <pod-name>
```

### Problema: Backend no conecta a MySQL

```bash
# Verificar que MySQL esté corriendo
kubectl get pods -n tienda-online -l app.kubernetes.io/component=database

# Verificar servicio
kubectl get svc -n tienda-online tienda-database

# Test de conectividad
kubectl exec -n tienda-online <backend-pod> -- nc -zv tienda-database 3306
```

### Problema: Prometheus no scraping métricas

```bash
# Verificar ServiceMonitor
kubectl get servicemonitor -n tienda-online

# Verificar targets en Prometheus UI
# http://localhost:9090/targets

# Ver logs de Prometheus
kubectl logs -n monitoring prometheus-prometheus-kube-prometheus-prometheus-0
```

### Problema: Kyverno bloquea despliegue

```bash
# Ver políticas
kubectl get clusterpolicies

# Ver detalles de rechazo
kubectl describe pod <pod-name> -n tienda-online

# Temporalmente cambiar a audit mode
kubectl patch clusterpolicy <policy-name> --type='json' \
  -p='[{"op": "replace", "path": "/spec/validationFailureAction", "value":"Audit"}]'
```

### Problema: Grafana no inicia (ConfigMap faltante)

```bash
# Verificar si el ConfigMap existe
kubectl get configmap grafana-dashboards -n monitoring

# Si no existe, crearlo
kubectl apply -f k8s/monitoring/grafana-dashboard-configmap.yaml

# Ver logs del pod de Grafana
kubectl logs -n monitoring -l app.kubernetes.io/name=grafana -c grafana

# Ver eventos del pod
kubectl describe pod -n monitoring -l app.kubernetes.io/name=grafana
```

### Problema: Falco no genera alertas

```bash
# Verificar que Falco esté corriendo
kubectl get pods -n falco

# Ver logs
kubectl logs -n falco -l app.kubernetes.io/name=falco -f

# Verificar reglas cargadas
kubectl exec -n falco <falco-pod> -- falco --list
```

---


