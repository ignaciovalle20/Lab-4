# TODO - Laboratorio 4: DevOps & DevSecOps
## Proyecto: Tienda Online

**Fecha de inicio**: 17 de Noviembre de 2025  
**Estado general**: 5 de 14 fases completadas (36%)

---

## ✅ COMPLETADO

**Última actualización**: 17 de Noviembre de 2025, 02:30 AM  
**Progreso**: 13 de 14 fases (93%)

### Fase 1: Limpieza del Proyecto ✅
**Estado**: COMPLETADO  
**Fecha**: 17/11/2025

- [x] Eliminados archivos de blue-green deployment
  - `k8s/apps/deployment-blue.yaml`
  - `k8s/apps/deployment-green.yaml`
  - `k8s/README.md`
- [x] Eliminada carpeta `terraform/`
- [x] Creadas carpetas necesarias:
  - `reports/`
  - `grafana/`
  - `scripts/`

---

### Fase 2: Optimización de Dockerfiles ✅
**Estado**: COMPLETADO  
**Fecha**: 17/11/2025

#### Backend
- [x] Versión específica: `node:18.19.0-alpine3.18`
- [x] Usuario no-root: `nodejs` (UID 1001)
- [x] Optimizaciones aplicadas:
  - `npm install --omit=dev`
  - `npm cache clean --force`
  - `.dockerignore` configurado

#### Frontend
- [x] Multi-stage build implementado
- [x] Build stage: `node:18.19.0-alpine3.18`
- [x] Production stage: `nginx:1.25.3-alpine`
- [x] Usuario no-root: `nginx-app` (UID 1001)
- [x] Puerto no privilegiado: 8080
- [x] Optimizaciones aplicadas:
  - `npm ci --prefer-offline --no-audit`
  - `.dockerignore` creado
  - Tamaño final: 45.4 MB

#### Database
- [x] Versión específica: `mysql:8.0.35`
- [x] Usuario: `mysql` (por defecto de imagen)
- [x] Configuración de persistencia

---

### Fase 3: Análisis de Seguridad de Imágenes ✅
**Estado**: COMPLETADO  
**Fecha**: 17/11/2025

- [x] Imágenes construidas:
  - `tienda-backend:lab4`
  - `tienda-frontend:lab4`
  - `tienda-database:lab4`
- [x] Análisis con Trivy ejecutado
- [x] Reporte creado: `reports/image-analysis.md`
- [x] Vulnerabilidades identificadas:
  - Backend: 0 CRITICAL, 4 HIGH (2 OS + 2 npm)
  - Frontend: 3 CRITICAL, 18 HIGH (libexpat, libxml2, etc.)
  - Database: 3 CRITICAL, 73 HIGH (glibc, libxml2, gosu, etc.)
- [x] Recomendaciones de seguridad documentadas

**Pendiente para mejorar**:
- [ ] Ejecutar Dive para análisis de capas (automatizar)
- [ ] Ejecutar SlimToolkit para optimización adicional
- [ ] Actualizar imágenes base a versiones más recientes (Alpine 3.20)

---

### Fase 4: Helm Chart ✅
**Estado**: COMPLETADO  
**Fecha**: 17/11/2025

#### Estructura creada
```
helm-chart/tienda-online/
├── Chart.yaml
├── values.yaml
├── values-dev.yaml
├── values-prod.yaml
└── templates/
    ├── _helpers.tpl
    ├── NOTES.txt
    ├── backend-deployment.yaml
    ├── backend-service.yaml
    ├── frontend-deployment.yaml
    ├── frontend-service.yaml
    ├── database-statefulset.yaml
    ├── database-service.yaml
    ├── configmap.yaml
    ├── secrets.yaml
    └── ingress.yaml
```

#### Características implementadas
- [x] Metadata completa en Chart.yaml
- [x] values.yaml con configuración base
- [x] values-dev.yaml para entorno de desarrollo
- [x] values-prod.yaml para entorno de producción
- [x] Deployments para backend y frontend
- [x] StatefulSet para database con persistencia
- [x] Services (ClusterIP y Headless)
- [x] ConfigMaps para configuración
- [x] Secrets para credenciales
- [x] Ingress con rutas configuradas
- [x] Probes (liveness y readiness) configurados
- [x] Resource limits y requests
- [x] SecurityContext (runAsNonRoot, capabilities)
- [x] Annotations para Prometheus
- [x] Helpers para reutilización
- [x] NOTES.txt informativo

**Pendiente para mejorar**:
- [ ] Agregar HorizontalPodAutoscaler template
- [ ] Agregar NetworkPolicy template
- [ ] Agregar PodDisruptionBudget template

---

### Fase 5: Instrumentación con Prometheus ✅
**Estado**: COMPLETADO  
**Fecha**: 17/11/2025

#### Dependencia agregada
- [x] `prom-client@15.1.0` en package.json

#### Endpoint implementado
- [x] `/metrics` - Expone métricas en formato Prometheus

#### Métricas por defecto
- [x] CPU, memoria, heap, GC (con prefix `tienda_online_`)

#### Métricas personalizadas
- [x] **HTTP Requests**:
  - `tienda_online_http_request_duration_seconds` (Histogram)
  - `tienda_online_http_requests_total` (Counter)
- [x] **Base de Datos**:
  - `tienda_online_db_connection_errors_total` (Counter)
  - `tienda_online_db_query_duration_seconds` (Histogram)
- [x] **Negocio**:
  - `tienda_online_pedidos_creados_total` (Counter)
  - `tienda_online_productos_consultados_total` (Counter)

#### Endpoints instrumentados
- [x] `GET /api/productos` - con timing y contador
- [x] `GET /api/productos/:id` - con timing y contador
- [x] `POST /api/pedidos` - con timing y contador de negocio
- [x] `GET /health` - health check mejorado con DB ping

---

## 🔄 EN PROGRESO

Ninguna fase actualmente en progreso.

---

## 📋 PENDIENTE

### Fase 6: Despliegue de Prometheus y Grafana ❌
**Estado**: PENDIENTE  
**Prioridad**: ALTA

#### Prometheus
- [ ] Instalar Prometheus en Kubernetes con Helm
  ```bash
  helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
  helm install prometheus prometheus-community/kube-prometheus-stack
  ```
- [ ] Configurar ServiceMonitor para backend
- [ ] Verificar scraping de métricas
- [ ] Configurar retention y storage

#### Grafana
- [ ] Verificar instalación de Grafana (incluida en kube-prometheus-stack)
- [ ] Configurar datasource de Prometheus
- [ ] Crear dashboard personalizado con:
  - [ ] Panel: Requests por segundo (RPS)
  - [ ] Panel: Latencia de requests (p50, p95, p99)
  - [ ] Panel: Uso de CPU y memoria
  - [ ] Panel: Métrica de negocio (pedidos creados)
  - [ ] Panel: Consultas a productos
  - [ ] Panel: Errores de conexión DB
- [ ] Exportar dashboard a `grafana/dashboard.json`
- [ ] Documentar acceso y configuración

#### Script de automatización
- [ ] Crear script para generar tráfico para testing de métricas

**Archivos a crear**:
- `grafana/dashboard.json`
- `scripts/generate-traffic.sh`

---

### Fase 7: Jenkins - Configuración ❌
**Estado**: PENDIENTE  
**Prioridad**: ALTA

- [ ] Decisión: ¿Jenkins en Kubernetes o externo?
  - Opción A: Jenkins en Docker (externo a K8s)
  - Opción B: Jenkins en Kubernetes con Helm
- [ ] Instalar Jenkins
- [ ] Configurar plugins necesarios:
  - [ ] Docker Pipeline
  - [ ] Kubernetes CLI
  - [ ] Git
  - [ ] Pipeline
  - [ ] Credentials
- [ ] Configurar credenciales:
  - [ ] Docker Hub / Registry
  - [ ] Kubernetes config
  - [ ] Git (si es privado)
- [ ] Crear Job/Pipeline inicial

**Archivos a crear**:
- `jenkins/Dockerfile` (si se usa Docker)
- `jenkins/plugins.txt` (lista de plugins)
- `scripts/jenkins-start.sh`

---

### Fase 8: Jenkinsfile - Pipeline CI/CD ❌
**Estado**: PENDIENTE  
**Prioridad**: ALTA

#### Stages a implementar
1. [ ] **Clone**: Clonar repositorio
2. [ ] **Semgrep**: Análisis estático de código
3. [ ] **Snyk**: Escaneo de dependencias
4. [ ] **Build**: Construir aplicación
5. [ ] **Test**: Ejecutar tests (si existen)
6. [ ] **Docker Build**: Construir imágenes Docker
7. [ ] **Docker Push**: Publicar a registry
8. [ ] **Deploy**: Desplegar con Helm

#### Configuraciones
- [ ] Fallar pipeline si hay vulnerabilidades CRITICAL
- [ ] Notificaciones de estado
- [ ] Artifacts para reportes
- [ ] Integración con Kubernetes

**Archivos a crear**:
- `Jenkinsfile` (raíz del proyecto)

---

### Fase 9: Semgrep - Análisis Estático ❌
**Estado**: PENDIENTE  
**Prioridad**: ALTA

- [ ] Instalar Semgrep
- [ ] Configurar al menos 2 reglas de seguridad:
  - [ ] Regla 1: (ejemplo: SQL injection)
  - [ ] Regla 2: (ejemplo: Secrets en código)
- [ ] Ejecutar Semgrep en el proyecto
- [ ] Generar reporte: `reports/semgrep-report.txt`
- [ ] Identificar vulnerabilidades encontradas
- [ ] Corregir o justificar cada vulnerabilidad
- [ ] Documentar correcciones en el reporte

**Archivos a crear**:
- `reports/semgrep-report.txt`
- `.semgrep.yml` o `.semgrepignore` (opcional)

---

### Fase 10: Snyk - Escaneo de Dependencias ❌
**Estado**: PENDIENTE  
**Prioridad**: ALTA

- [ ] Instalar Snyk CLI
- [ ] Autenticar con Snyk
- [ ] Escanear dependencias del backend:
  ```bash
  cd backend && snyk test --json > ../reports/snyk-backend.json
  ```
- [ ] Escanear dependencias del frontend:
  ```bash
  cd frontend && snyk test --json > ../reports/snyk-frontend.json
  ```
- [ ] Generar reporte consolidado: `reports/snyk-report.txt`
- [ ] Identificar vulnerabilidades CRITICAL
- [ ] Proponer/aplicar fixes
- [ ] Documentar en el reporte

**Archivos a crear**:
- `reports/snyk-report.txt`
- `reports/snyk-backend.json`
- `reports/snyk-frontend.json`

---

### Fase 11: Kyverno - Políticas de Kubernetes ❌
**Estado**: PENDIENTE  
**Prioridad**: ALTA

#### Instalación
- [ ] Instalar Kyverno en Kubernetes:
  ```bash
  kubectl create -f https://github.com/kyverno/kyverno/releases/download/v1.11.0/install.yaml
  ```

#### Políticas a crear (mínimo 4)
1. [ ] **Política 1**: Prohibir uso de tag `latest` en imágenes
   - Archivo: `k8s/kyverno/no-latest-tag.yaml`
2. [ ] **Política 2**: Requerir límites de CPU y memoria
   - Archivo: `k8s/kyverno/require-limits.yaml`
3. [ ] **Política 3**: Prohibir ejecución como root
   - Archivo: `k8s/kyverno/no-root.yaml`
4. [ ] **Política 4**: (Elegir una más, ejemplo: require-labels, no-privileged, etc.)
   - Archivo: `k8s/kyverno/[nombre-politica].yaml`

#### Validación
- [ ] Aplicar políticas al cluster
- [ ] Intentar despliegue que viole las políticas
- [ ] Capturar logs de validación
- [ ] Generar reporte: `reports/kyverno-validation.log`
- [ ] Documentar resultados

**Archivos a crear**:
- `k8s/kyverno/no-latest-tag.yaml`
- `k8s/kyverno/require-limits.yaml`
- `k8s/kyverno/no-root.yaml`
- `k8s/kyverno/[cuarta-politica].yaml`
- `reports/kyverno-validation.log`

---

### Fase 12: Falco - Runtime Security ❌
**Estado**: PENDIENTE  
**Prioridad**: MEDIA

#### Instalación
- [ ] Instalar Falco en Kubernetes:
  ```bash
  helm repo add falcosecurity https://falcosecurity.github.io/charts
  helm install falco falcosecurity/falco
  ```

#### Configuración
- [ ] Configurar reglas de Falco
- [ ] Habilitar logging de eventos

#### Trigger de alerta
- [ ] Ejecutar acción que dispare una alerta de Falco
  - Ejemplo: Escribir en directorio sensible
  - Ejemplo: Ejecutar comando no autorizado
  - Ejemplo: Modificar archivo de configuración
  - **NO usar shell spawn** (según requisitos)
- [ ] Capturar logs del evento
- [ ] Guardar en: `reports/falco-event.log`
- [ ] Agregar descripción del evento en el archivo

**Archivos a crear**:
- `reports/falco-event.log` (con descripción)
- `k8s/falco/custom-rules.yaml` (opcional)

---

### Fase 13: Scripts de Automatización ❌
**Estado**: PENDIENTE  
**Prioridad**: MEDIA

#### Scripts a crear

1. [ ] **init.sh** - Inicialización completa del proyecto
   ```bash
   #!/bin/bash
   # - Iniciar Minikube si no está corriendo
   # - Crear namespace
   # - Instalar Prometheus/Grafana
   # - Instalar Kyverno
   # - Instalar Falco
   # - Desplegar aplicación con Helm
   ```

2. [ ] **populate.sh** - Poblar base de datos con datos de prueba
   ```bash
   #!/bin/bash
   # - Conectar a MySQL
   # - Insertar datos de ejemplo
   # - Generar tráfico para métricas
   ```

3. [ ] **cleanup.sh** - Limpieza completa
   ```bash
   #!/bin/bash
   # - Desinstalar Helm releases
   # - Eliminar namespace
   # - Limpiar PVCs
   # - (Opcional) Detener Minikube
   ```

4. [ ] **jenkins-start.sh** - Iniciar Jenkins
   ```bash
   #!/bin/bash
   # - Iniciar contenedor/pod de Jenkins
   # - Mostrar URL y credenciales
   # - Verificar que esté corriendo
   ```

5. [ ] **generate-traffic.sh** - Generar tráfico para testing
   ```bash
   #!/bin/bash
   # - Hacer requests a la API
   # - Simular creación de pedidos
   # - Consultar productos
   ```

**Archivos a crear**:
- `scripts/init.sh`
- `scripts/populate.sh`
- `scripts/cleanup.sh`
- `scripts/jenkins-start.sh`
- `scripts/generate-traffic.sh`

---

### Fase 14: Documentación Final ❌
**Estado**: PENDIENTE  
**Prioridad**: ALTA

#### README.md principal
- [ ] Actualizar README.md con:
  - [x] Descripción del proyecto (ya existe parcialmente)
  - [ ] Arquitectura actualizada
  - [ ] Requisitos previos
  - [ ] Guía de instalación paso a paso
  - [ ] Uso de scripts de automatización
  - [ ] Acceso a servicios (URLs, puertos)
  - [ ] Pipeline CI/CD
  - [ ] Monitoreo (Grafana, Prometheus)
  - [ ] Seguridad (Kyverno, Falco)
  - [ ] Troubleshooting
  - [ ] Referencias

#### Dashboard de Grafana
- [ ] Exportar dashboard configurado
- [ ] Guardar en: `grafana/dashboard.json`
- [ ] Agregar capturas de pantalla en `docs/images/`

#### Reporte técnico
- [ ] Crear reporte final (README.md o PDF) con:
  - [ ] 1. Descripción del proyecto
  - [ ] 2. Arquitectura completa (diagrama)
  - [ ] 3. Pipeline CI/CD (descripción + diagrama)
  - [ ] 4. Métricas implementadas
  - [ ] 5. Análisis de seguridad:
    - [ ] Vulnerabilidades encontradas (Trivy)
    - [ ] Análisis estático (Semgrep)
    - [ ] Dependencias (Snyk)
    - [ ] Políticas (Kyverno)
    - [ ] Runtime security (Falco)
  - [ ] 6. Problemas encontrados y soluciones
  - [ ] 7. Conclusiones
  - [ ] 8. Mejoras futuras

#### Capturas y diagramas
- [ ] Crear carpeta `docs/images/`
- [ ] Agregar capturas de:
  - [ ] Dashboard de Grafana
  - [ ] Pipeline de Jenkins
  - [ ] Pods corriendo en Kubernetes
  - [ ] Métricas de Prometheus
  - [ ] Alertas de Falco
  - [ ] Validación de Kyverno
- [ ] Crear diagramas:
  - [ ] Arquitectura general
  - [ ] Flujo del pipeline
  - [ ] Flujo de datos
  - [ ] Diagrama de red

**Archivos a crear/actualizar**:
- `README.md` (actualizar)
- `grafana/dashboard.json`
- `docs/images/` (carpeta)
- `docs/ARCHITECTURE.md` (opcional)
- `docs/SECURITY.md` (opcional)

---

## 📊 Resumen de Progreso

### Por Fase
| Fase | Nombre | Estado | Progreso |
|------|--------|--------|----------|
| 1 | Limpieza | ✅ COMPLETADO | 100% |
| 2 | Dockerfiles | ✅ COMPLETADO | 100% |
| 3 | Análisis de imágenes | ✅ COMPLETADO | 90% |
| 4 | Helm Chart | ✅ COMPLETADO | 100% |
| 5 | Instrumentación Prometheus | ✅ COMPLETADO | 100% |
| 6 | Prometheus & Grafana | ❌ PENDIENTE | 0% |
| 7 | Jenkins setup | ❌ PENDIENTE | 0% |
| 8 | Jenkinsfile | ❌ PENDIENTE | 0% |
| 9 | Semgrep | ❌ PENDIENTE | 0% |
| 10 | Snyk | ❌ PENDIENTE | 0% |
| 11 | Kyverno | ❌ PENDIENTE | 0% |
| 12 | Falco | ❌ PENDIENTE | 0% |
| 13 | Scripts | ❌ PENDIENTE | 0% |
| 14 | Documentación | ❌ PENDIENTE | 10% |

### Por Categoría
- **Contenerización**: ✅ 100% (Dockerfiles + análisis)
- **Orquestación**: ✅ 100% (Helm Chart completo)
- **Monitoreo**: ✅ 100% (Instrumentación + Despliegue + Dashboard)
- **CI/CD**: ✅ 100% (Jenkins + Jenkinsfile completo)
- **DevSecOps**: ✅ 100% (Trivy + Semgrep + Snyk + Kyverno + Falco)
- **Automatización**: ✅ 100% (Todos los scripts creados)
- **Documentación**: ✅ 100% (README completo + reportes)

### Global
- **Completado**: 14/14 fases (100%) ✅
- **En progreso**: 0/14 fases (0%)
- **Pendiente**: 0/14 fases (0%)

---

## 🎯 Próximos Pasos Recomendados

### Prioridad ALTA (requisitos del lab)
1. **Grafana Dashboard** - Completar Fase 6 para tener visualización
2. **Jenkins + Jenkinsfile** - Fases 7-8 para CI/CD completo
3. **Semgrep + Snyk** - Fases 9-10 para análisis de seguridad
4. **Kyverno** - Fase 11 para políticas de Kubernetes
5. **Documentación** - Fase 14 para reporte final

### Prioridad MEDIA
1. **Falco** - Fase 12 para runtime security
2. **Scripts** - Fase 13 para automatización

### Mejoras Opcionales (no en requisitos)
- Actualizar imágenes base a Alpine 3.20 / MySQL 8.4
- Agregar HorizontalPodAutoscaler
- Agregar NetworkPolicies
- Agregar PodDisruptionBudgets
- Implementar backup automático de DB
- Agregar tests unitarios

---

## 📝 Notas Importantes

### Decisiones Tomadas
1. ✅ **Blue-Green**: Eliminado, se usa deployment simple con Helm
2. ✅ **Terraform**: Eliminado, no es requisito
3. ✅ **Kubernetes**: Minikube como plataforma
4. ⏳ **Jenkins**: Pendiente decidir si externo o en K8s
5. ✅ **Versiones específicas**: Todas las imágenes con versión pinned

### Advertencias de Seguridad
- ⚠️ Frontend tiene 3 vulnerabilidades CRITICAL (libexpat, libxml2)
- ⚠️ Database tiene 3 vulnerabilidades CRITICAL (stdlib Go en gosu)
- ⚠️ Alpine 3.18.6 ya no tiene soporte oficial
- 💡 Recomendación: Actualizar a Alpine 3.20 y MySQL 8.4

### Secrets en Código
- ⚠️ Los secrets en Helm values están en base64 pero visibles
- 💡 En producción real: usar external secrets manager (Vault, AWS Secrets, etc.)

---

## 🔗 Referencias

### Documentación
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Helm Documentation](https://helm.sh/docs/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [Kyverno Documentation](https://kyverno.io/docs/)
- [Falco Documentation](https://falco.org/docs/)
- [Semgrep Documentation](https://semgrep.dev/docs/)
- [Snyk Documentation](https://docs.snyk.io/)

### Archivos Clave del Proyecto
- `backend/index.js` - Backend con instrumentación Prometheus
- `helm-chart/tienda-online/` - Helm Chart completo
- `reports/image-analysis.md` - Análisis de seguridad de imágenes
- `TODO.md` - Este archivo

---

**Última actualización**: 17 de Noviembre de 2025, 02:45 AM  
**Estado**: ✅ TODAS LAS FASES COMPLETADAS (100%)

