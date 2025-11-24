# Monitoreo con Prometheus y Grafana

Este directorio contiene la configuración para desplegar Prometheus y Grafana en Kubernetes para monitorear la aplicación Tienda Online.

## 📁 Archivos

- **`prometheus-values.yaml`**: Configuración personalizada para kube-prometheus-stack
- **`servicemonitor.yaml`**: ServiceMonitor para scraping del backend
- **`grafana-dashboard-configmap.yaml`**: ConfigMap con dashboard preconfigurado
- **`README.md`**: Este archivo

## 🚀 Instalación

### 1. Iniciar Minikube (si no está corriendo)

```bash
minikube start
```

### 2. Crear namespace para monitoreo

```bash
kubectl create namespace monitoring
```

### 3. Agregar repositorio de Helm

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

### 4. Instalar kube-prometheus-stack

```bash
helm install prometheus prometheus-community/kube-prometheus-stack \
  -n monitoring \
  -f k8s/monitoring/prometheus-values.yaml \
  --create-namespace
```

Este comando instala:
- ✅ Prometheus Server
- ✅ Grafana
- ✅ Alertmanager
- ✅ Node Exporter
- ✅ Kube State Metrics
- ✅ Prometheus Operator

### 5. Verificar instalación

```bash
# Ver pods del namespace monitoring
kubectl get pods -n monitoring

# Esperar a que todos los pods estén Running
kubectl wait --for=condition=ready pod -l "app.kubernetes.io/instance=prometheus" -n monitoring --timeout=300s
```

### 6. Crear namespace de la aplicación

```bash
kubectl create namespace tienda-online
```

### 7. Desplegar la aplicación con Helm

```bash
helm install tienda-online ./helm-chart/tienda-online \
  -n tienda-online \
  -f helm-chart/tienda-online/values-dev.yaml
```

### 8. Aplicar ServiceMonitor

```bash
kubectl apply -f k8s/monitoring/servicemonitor.yaml
```

### 9. Aplicar dashboard de Grafana (opcional)

```bash
kubectl apply -f k8s/monitoring/grafana-dashboard-configmap.yaml
```

## 🔍 Acceso a los Servicios

### Prometheus

```bash
# Port forward
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090

# Acceder en el navegador
open http://localhost:9090
```

### Grafana

```bash
# Port forward
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# Acceder en el navegador
open http://localhost:3000

# Credenciales por defecto
Usuario: admin
Password: admin123
```

### Alertmanager

```bash
# Port forward
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-alertmanager 9093:9093

# Acceder en el navegador
open http://localhost:9093
```

## 📊 Dashboard de Grafana

El dashboard personalizado incluye los siguientes paneles:

### 1. HTTP Requests per Second (RPS)
- Visualiza la tasa de requests HTTP por segundo
- Desglosado por método, ruta y código de estado

### 2. HTTP Request Latency
- Muestra latencia de requests (p50, p95, p99)
- Importante para detectar problemas de performance

### 3. CPU Usage
- Uso de CPU del proceso Node.js
- Útil para identificar picos de procesamiento

### 4. Memory Usage
- Memoria RSS, Heap Used y Heap Total
- Importante para detectar memory leaks

### 5. Total Pedidos Creados
- Contador de pedidos creados (métrica de negocio)
- Gauge que muestra el total acumulado

### 6. Tasa de Creación de Pedidos
- Pedidos creados por segundo
- Métrica de negocio para monitorear actividad

### 7. Total Productos Consultados
- Contador de consultas a productos
- Métrica de negocio para entender el uso

### 8. Errores de Conexión a BD
- Errores de conexión a MySQL
- Crítico para detectar problemas de infraestructura

### 9. Database Query Latency
- Latencia de queries a la BD (p95)
- Importante para optimizar consultas

## 📈 Métricas Disponibles

### Métricas HTTP
- `tienda_online_http_requests_total`: Total de requests HTTP
- `tienda_online_http_request_duration_seconds`: Duración de requests HTTP

### Métricas de Base de Datos
- `tienda_online_db_connection_errors_total`: Errores de conexión a BD
- `tienda_online_db_query_duration_seconds`: Duración de queries

### Métricas de Negocio
- `tienda_online_pedidos_creados_total`: Total de pedidos creados
- `tienda_online_productos_consultados_total`: Total de productos consultados

### Métricas del Sistema (automáticas)
- `tienda_online_process_cpu_seconds_total`: CPU usage
- `tienda_online_process_resident_memory_bytes`: Memoria RSS
- `tienda_online_nodejs_heap_size_used_bytes`: Heap usado
- `tienda_online_nodejs_heap_size_total_bytes`: Heap total
- Y muchas más...

## 🧪 Generar Tráfico para Testing

Para poblar las métricas con datos, usa el script de generación de tráfico:

```bash
# Port forward del backend primero
kubectl port-forward -n tienda-online svc/tienda-backend 30000:5000

# En otra terminal, generar tráfico por 5 minutos (300 segundos)
./scripts/generate-traffic.sh http://localhost:30000 http://localhost:30001 300
```

El script genera automáticamente:
- ✅ Consultas a productos
- ✅ Creación de pedidos
- ✅ Health checks
- ✅ Accesos al frontend

## 🔧 Troubleshooting

### Prometheus no scraping métricas

```bash
# Verificar que el ServiceMonitor esté creado
kubectl get servicemonitor -n tienda-online

# Verificar logs de Prometheus
kubectl logs -n monitoring prometheus-prometheus-kube-prometheus-prometheus-0

# Verificar targets en Prometheus UI
# http://localhost:9090/targets
```

### Grafana no muestra datos

1. Verificar que el datasource de Prometheus esté configurado
2. En Grafana → Configuration → Data Sources → Prometheus
3. URL debe ser: `http://prometheus-kube-prometheus-prometheus:9090`
4. Click en "Test" para verificar conexión

### Backend no expone métricas

```bash
# Verificar endpoint /metrics
kubectl port-forward -n tienda-online svc/tienda-backend 5000:5000
curl http://localhost:5000/metrics

# Debe retornar métricas en formato Prometheus
```

### Dashboard no carga

```bash
# Importar manualmente el dashboard
# 1. Ir a Grafana → Dashboards → Import
# 2. Copiar contenido de grafana/dashboard.json
# 3. Pegar y hacer click en "Load"
```

## 📦 Desinstalación

```bash
# Desinstalar kube-prometheus-stack
helm uninstall prometheus -n monitoring

# Eliminar CRDs (si es necesario)
kubectl delete crd alertmanagerconfigs.monitoring.coreos.com
kubectl delete crd alertmanagers.monitoring.coreos.com
kubectl delete crd podmonitors.monitoring.coreos.com
kubectl delete crd probes.monitoring.coreos.com
kubectl delete crd prometheuses.monitoring.coreos.com
kubectl delete crd prometheusrules.monitoring.coreos.com
kubectl delete crd servicemonitors.monitoring.coreos.com
kubectl delete crd thanosrulers.monitoring.coreos.com

# Eliminar namespace
kubectl delete namespace monitoring
```

## 📚 Referencias

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [kube-prometheus-stack Chart](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
- [prom-client (Node.js)](https://github.com/siimon/prom-client)
- [ServiceMonitor CRD](https://github.com/prometheus-operator/prometheus-operator/blob/main/Documentation/api.md#servicemonitor)

## 🎯 Próximos Pasos

1. ✅ Prometheus y Grafana instalados
2. ✅ ServiceMonitor configurado
3. ✅ Dashboard creado
4. ⏳ Configurar alertas en Alertmanager
5. ⏳ Agregar más dashboards (infraestructura, MySQL, etc.)
6. ⏳ Configurar notificaciones (Slack, email, etc.)

