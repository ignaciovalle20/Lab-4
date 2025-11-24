# Falco - Runtime Security Monitoring

Este directorio contiene la configuración de Falco para monitoreo de seguridad en tiempo de ejecución en Kubernetes.

## 📁 Archivos

- **`custom-rules.yaml`**: Reglas personalizadas de Falco
- **`README.md`**: Este archivo

## 🚀 Instalación de Falco

### 1. Agregar repositorio de Helm

```bash
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm repo update
```

### 2. Instalar Falco con Helm

```bash
helm install falco falcosecurity/falco \
  --namespace falco \
  --create-namespace \
  --set tty=true \
  --set driver.kind=modern_ebpf \
  --set falco.grpc.enabled=true \
  --set falco.grpc_output.enabled=true \
  --set falco.json_output=true \
  --set falco.log_stderr=true \
  --set falco.log_syslog=false \
  --set falco.log_level=info \
  --set falco.priority=debug
```

### 3. Verificar instalación

```bash
# Ver pods de Falco
kubectl get pods -n falco

# Debe mostrar:
# NAME          READY   STATUS    RESTARTS   AGE
# falco-xxxxx   1/1     Running   0          2m

# Verificar logs de Falco
kubectl logs -n falco -l app.kubernetes.io/name=falco --tail=50
```

### 4. Aplicar reglas personalizadas (opcional)

```bash
kubectl apply -f k8s/falco/custom-rules.yaml
```

## 🔍 Reglas por Defecto de Falco

Falco viene con reglas preconfiguradas que detectan:

### 1. Accesos sospechosos a archivos
- Lectura de archivos sensibles (`/etc/shadow`, `/etc/sudoers`)
- Modificación de binarios del sistema
- Escritura en directorios críticos (`/bin`, `/usr/bin`)

### 2. Ejecución de comandos sospechosos
- Shells interactivas en contenedores
- Uso de herramientas de red (netcat, nmap)
- Modificación de configuración de red

### 3. Cambios en configuración
- Modificación de archivos de configuración del sistema
- Cambios en reglas de iptables
- Modificación de cron jobs

### 4. Actividad de red sospechosa
- Conexiones a puertos no autorizados
- Tráfico inusual
- Escaneo de puertos

## 🧪 Generar Eventos de Falco

### Método 1: Leer archivo sensible

```bash
# Ejecutar comando en un pod
kubectl exec -it -n tienda-online <nombre-del-pod> -- cat /etc/shadow

# Esto generará una alerta:
# "Read sensitive file untrusted"
```

### Método 2: Escribir en directorio del sistema

```bash
# Crear un archivo en /bin
kubectl exec -it -n tienda-online <nombre-del-pod> -- touch /bin/test-file

# Esto generará una alerta:
# "Write below binary dir"
```

### Método 3: Modificar archivo de configuración

```bash
# Modificar /etc/passwd
kubectl exec -it -n tienda-online <nombre-del-pod> -- sh -c "echo test >> /etc/passwd"

# Esto generará una alerta:
# "Modify /etc/passwd"
```

### Método 4: Crear un pod que modifique archivos del sistema

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: falco-trigger
  namespace: tienda-online
  labels:
    app.kubernetes.io/name: falco-trigger
    app.kubernetes.io/version: "1.0.0"
    app.kubernetes.io/component: test
    app.kubernetes.io/managed-by: kubectl
spec:
  securityContext:
    runAsNonRoot: true
  containers:
  - name: alpine
    image: alpine:3.18.6
    command: ["/bin/sh"]
    args:
    - -c
    - |
      # Acción 1: Leer archivo sensible
      echo "Reading /etc/shadow..."
      cat /etc/shadow 2>/dev/null || echo "/etc/shadow not accessible"
      
      # Acción 2: Intentar escribir en directorio protegido
      echo "Attempting to write to /etc..."
      touch /etc/test-file 2>/dev/null || echo "Cannot write to /etc"
      
      # Acción 3: Modificar variable de entorno sensible
      echo "Modifying environment..."
      export LD_PRELOAD=/tmp/malicious.so
      
      # Mantener el contenedor corriendo
      sleep 3600
    securityContext:
      runAsNonRoot: true
      runAsUser: 1001
      allowPrivilegeEscalation: false
      capabilities:
        drop:
        - ALL
    resources:
      requests:
        cpu: "10m"
        memory: "32Mi"
      limits:
        cpu: "50m"
        memory: "64Mi"
```

Aplicar y ver logs:

```bash
# Aplicar el pod
kubectl apply -f falco-trigger-pod.yaml

# Ver logs de Falco para detectar alertas
kubectl logs -n falco -l app.kubernetes.io/name=falco --tail=100 -f

# Limpiar
kubectl delete pod falco-trigger -n tienda-online
```

## 📊 Ver Alertas de Falco

### Ver todas las alertas

```bash
# Ver logs en tiempo real
kubectl logs -n falco -l app.kubernetes.io/name=falco -f

# Ver últimas 100 líneas
kubectl logs -n falco -l app.kubernetes.io/name=falco --tail=100

# Filtrar solo alertas (priority >= WARNING)
kubectl logs -n falco -l app.kubernetes.io/name=falco --tail=200 | grep -E "Warning|Error|Critical|Alert"

# Filtrar alertas en formato JSON
kubectl logs -n falco -l app.kubernetes.io/name=falco --tail=200 | grep "^{"
```

### Formato de las alertas

Las alertas de Falco tienen este formato:

```
<timestamp> <priority>: <rule_name> (user=<user> command=<command> ...details...)
```

Ejemplo:
```
14:35:21.123456789: Warning Read sensitive file untrusted (user=root command=cat /etc/shadow file=/etc/shadow)
```

En formato JSON:
```json
{
  "output": "14:35:21.123456789: Warning Read sensitive file untrusted (user=root command=cat /etc/shadow file=/etc/shadow)",
  "priority": "Warning",
  "rule": "Read sensitive file untrusted",
  "time": "2025-11-17T14:35:21.123456789Z",
  "output_fields": {
    "user.name": "root",
    "proc.cmdline": "cat /etc/shadow",
    "fd.name": "/etc/shadow"
  }
}
```

## 📈 Integración con Prometheus

Falco puede exportar métricas a Prometheus:

### 1. Habilitar Falco Exporter

```bash
helm install falco-exporter falcosecurity/falco-exporter \
  --namespace falco \
  --set serviceMonitor.enabled=true
```

### 2. Ver métricas

```bash
# Port forward
kubectl port-forward -n falco svc/falco-exporter 9376:9376

# Ver métricas
curl http://localhost:9376/metrics | grep falco
```

Métricas disponibles:
- `falco_events_total`: Total de eventos por regla
- `falco_events_rate`: Tasa de eventos por segundo
- `falco_alerts_total`: Total de alertas por prioridad

## 🔧 Troubleshooting

### Falco no inicia

```bash
# Ver estado del pod
kubectl describe pod -n falco -l app.kubernetes.io/name=falco

# Ver logs de inicio
kubectl logs -n falco -l app.kubernetes.io/name=falco --tail=100

# Verificar que el driver esté cargado
kubectl exec -n falco -it $(kubectl get pod -n falco -l app.kubernetes.io/name=falco -o name | head -1) -- falco-driver-loader
```

### No se generan alertas

1. Verificar que Falco esté en modo debug:
   ```bash
   kubectl logs -n falco -l app.kubernetes.io/name=falco | grep "Enabled event sources"
   ```

2. Verificar que las reglas estén cargadas:
   ```bash
   kubectl exec -n falco -it $(kubectl get pod -n falco -l app.kubernetes.io/name=falco -o name | head -1) -- falco --list
   ```

3. Probar con un evento simple:
   ```bash
   kubectl run test --image=alpine --rm -it -- cat /etc/shadow
   ```

### Performance issues

Si Falco consume muchos recursos:

```bash
# Reducir verbosidad de logs
helm upgrade falco falcosecurity/falco \
  --namespace falco \
  --set falco.log_level=warning \
  --set falco.priority=warning

# Deshabilitar reglas no críticas
# Editar custom-rules.yaml y agregar 'enabled: false' a reglas específicas
```

## 🧹 Desinstalación

```bash
# Desinstalar Falco
helm uninstall falco -n falco

# Desinstalar Falco Exporter (si está instalado)
helm uninstall falco-exporter -n falco

# Eliminar namespace
kubectl delete namespace falco
```

## 📚 Referencias

- [Falco Documentation](https://falco.org/docs/)
- [Falco Rules](https://github.com/falcosecurity/rules)
- [Falco Helm Chart](https://github.com/falcosecurity/charts/tree/master/charts/falco)
- [Falco Alerts Best Practices](https://falco.org/docs/rules/default-rules/)
- [CNCF Falco](https://www.cncf.io/projects/falco/)

## 🎯 Próximos Pasos

1. ✅ Falco instalado
2. ⏳ Generar eventos de prueba
3. ⏳ Capturar y documentar alertas
4. ⏳ Configurar integración con sistemas de alerta (Slack, PagerDuty)
5. ⏳ Crear dashboard de alertas en Grafana

