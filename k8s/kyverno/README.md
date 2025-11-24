# Kyverno - Políticas de Seguridad de Kubernetes

Este directorio contiene políticas de Kyverno para aplicar mejores prácticas de seguridad y gobernanza en el cluster de Kubernetes.

## 📁 Archivos

- **`no-latest-tag.yaml`**: Prohíbe el uso del tag `latest` en imágenes
- **`require-limits.yaml`**: Requiere que todos los contenedores tengan límites de recursos
- **`no-root.yaml`**: Prohíbe la ejecución de contenedores como root
- **`require-labels.yaml`**: Requiere etiquetas estándar de Kubernetes
- **`README.md`**: Este archivo

## 🚀 Instalación de Kyverno

### 1. Instalar Kyverno en el cluster

```bash
# Opción 1: Con Helm (recomendado)
helm repo add kyverno https://kyverno.github.io/kyverno/
helm repo update
helm install kyverno kyverno/kyverno \
  --namespace kyverno \
  --create-namespace \
  --version 3.1.4

# Opción 2: Con kubectl
kubectl create -f https://github.com/kyverno/kyverno/releases/download/v1.11.0/install.yaml
```

### 2. Verificar instalación

```bash
# Ver pods de Kyverno
kubectl get pods -n kyverno

# Debe mostrar:
# NAME                                READY   STATUS    RESTARTS   AGE
# kyverno-admission-controller-xxx    1/1     Running   0          2m
# kyverno-background-controller-xxx   1/1     Running   0          2m
# kyverno-cleanup-controller-xxx      1/1     Running   0          2m
# kyverno-reports-controller-xxx      1/1     Running   0          2m

# Verificar que Kyverno esté listo
kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=kyverno -n kyverno --timeout=300s
```

### 3. Aplicar las políticas

```bash
# Aplicar todas las políticas
kubectl apply -f k8s/kyverno/

# O una por una
kubectl apply -f k8s/kyverno/no-latest-tag.yaml
kubectl apply -f k8s/kyverno/require-limits.yaml
kubectl apply -f k8s/kyverno/no-root.yaml
kubectl apply -f k8s/kyverno/require-labels.yaml
```

### 4. Verificar políticas

```bash
# Ver todas las políticas instaladas
kubectl get clusterpolicies

# Ver detalles de una política específica
kubectl describe clusterpolicy disallow-latest-tag

# Ver estado de las políticas
kubectl get policyreport -A
```

## 📋 Políticas Implementadas

### 1. Disallow Latest Tag (no-latest-tag.yaml)

**Objetivo**: Prevenir el uso del tag `latest` en imágenes de contenedores.

**Razón**: 
- El tag `latest` es mutable y puede cambiar entre despliegues
- Causa inconsistencias entre ambientes (dev, staging, prod)
- Dificulta el rollback a versiones anteriores
- Complica la auditoría y troubleshooting

**Severidad**: MEDIUM

**Validación**:
- ✅ Todas las imágenes deben tener un tag explícito y específico
- ✅ Se valida tanto en containers como en initContainers
- ❌ Rechaza imágenes con tag `:latest`
- ❌ Rechaza imágenes sin tag (usan `latest` por defecto)

**Ejemplo de violación**:
```yaml
# ❌ RECHAZADO
containers:
  - name: backend
    image: tienda-backend:latest  # Tag 'latest' no permitido
  - name: frontend
    image: tienda-frontend  # Sin tag = 'latest' implícito
```

**Ejemplo correcto**:
```yaml
# ✅ ACEPTADO
containers:
  - name: backend
    image: tienda-backend:1.0.0  # Tag específico
  - name: frontend
    image: tienda-frontend:v2.3.1  # Tag específico
```

---

### 2. Require Resource Limits (require-limits.yaml)

**Objetivo**: Garantizar que todos los contenedores tengan límites de CPU y memoria definidos.

**Razón**:
- Previene que un contenedor consuma todos los recursos del nodo
- Mejora la estabilidad del cluster
- Permite al scheduler tomar mejores decisiones
- Facilita el capacity planning

**Severidad**: MEDIUM

**Validación**:
- ✅ Todos los contenedores deben tener `resources.requests.cpu` y `resources.requests.memory`
- ✅ Todos los contenedores deben tener `resources.limits.cpu` y `resources.limits.memory`
- ✅ Se valida tanto en containers como en initContainers
- ✅ Valida que los límites sean razonables (entre 64Mi-8Gi para memoria)

**Ejemplo de violación**:
```yaml
# ❌ RECHAZADO - Sin recursos
containers:
  - name: backend
    image: tienda-backend:1.0.0
    # Sin resources definidos

# ❌ RECHAZADO - Solo requests, faltan limits
containers:
  - name: backend
    image: tienda-backend:1.0.0
    resources:
      requests:
        cpu: "100m"
        memory: "128Mi"
      # Faltan limits
```

**Ejemplo correcto**:
```yaml
# ✅ ACEPTADO
containers:
  - name: backend
    image: tienda-backend:1.0.0
    resources:
      requests:
        cpu: "100m"
        memory: "128Mi"
      limits:
        cpu: "500m"
        memory: "512Mi"
```

---

### 3. Disallow Root User (no-root.yaml)

**Objetivo**: Prohibir la ejecución de contenedores como usuario root.

**Razón**:
- Ejecutar como root aumenta la superficie de ataque
- Si el contenedor es comprometido, el atacante tiene privilegios de root
- Principio de mínimos privilegios
- Cumplimiento con Pod Security Standards (Restricted)

**Severidad**: HIGH

**Validación**:
- ✅ `securityContext.runAsNonRoot` debe ser `true`
- ✅ `securityContext.runAsUser` debe ser > 0
- ✅ `securityContext.allowPrivilegeEscalation` debe ser `false`
- ✅ `securityContext.privileged` debe ser `false` o no definido
- ✅ Se valida tanto en containers como en initContainers

**Ejemplo de violación**:
```yaml
# ❌ RECHAZADO - Sin securityContext
containers:
  - name: backend
    image: tienda-backend:1.0.0
    # Sin securityContext

# ❌ RECHAZADO - runAsUser es 0 (root)
containers:
  - name: backend
    image: tienda-backend:1.0.0
    securityContext:
      runAsUser: 0  # 0 = root

# ❌ RECHAZADO - privileged: true
containers:
  - name: backend
    image: tienda-backend:1.0.0
    securityContext:
      privileged: true
```

**Ejemplo correcto**:
```yaml
# ✅ ACEPTADO
spec:
  securityContext:
    runAsNonRoot: true
  containers:
  - name: backend
    image: tienda-backend:1.0.0
    securityContext:
      runAsNonRoot: true
      runAsUser: 1001
      allowPrivilegeEscalation: false
```

---

### 4. Require Labels (require-labels.yaml)

**Objetivo**: Requerir etiquetas estándar de Kubernetes en todos los recursos.

**Razón**:
- Facilita la gestión y organización de recursos
- Mejora el monitoreo y observabilidad
- Simplifica troubleshooting y debugging
- Permite políticas de red y RBAC más granulares
- Cumplimiento con convenciones de Kubernetes

**Severidad**: LOW

**Etiquetas requeridas** (según [Kubernetes Recommended Labels](https://kubernetes.io/docs/concepts/overview/working-with-objects/common-labels/)):
- `app.kubernetes.io/name`: Nombre de la aplicación
- `app.kubernetes.io/version`: Versión de la aplicación
- `app.kubernetes.io/component`: Rol del componente (backend, frontend, database)
- `app.kubernetes.io/managed-by`: Herramienta que gestiona el recurso (Helm, kubectl)

**Validación**:
- ✅ Valida que las etiquetas estén presentes
- ✅ Valida que los valores no excedan 63 caracteres
- ✅ Se aplica a: Pod, Deployment, StatefulSet, Service, ConfigMap, Secret

**Ejemplo de violación**:
```yaml
# ❌ RECHAZADO - Faltan etiquetas
metadata:
  name: tienda-backend
  labels:
    app: backend  # Etiquetas no estándar
```

**Ejemplo correcto**:
```yaml
# ✅ ACEPTADO
metadata:
  name: tienda-backend
  labels:
    app.kubernetes.io/name: tienda-online
    app.kubernetes.io/version: "1.0.0"
    app.kubernetes.io/component: backend
    app.kubernetes.io/managed-by: Helm
```

## 🧪 Testing y Validación

### Probar Política 1: No Latest Tag

```bash
# ❌ Intentar desplegar con tag 'latest' (debe FALLAR)
kubectl run test-latest --image=nginx:latest -n tienda-online

# Resultado esperado:
# Error from server: admission webhook "validate.kyverno.svc-fail" denied the request:
# policy Pod/tienda-online/test-latest for resource violation:
# disallow-latest-tag:
#   require-image-tag: validation error: El uso del tag 'latest' no está permitido...

# ✅ Desplegar con tag específico (debe FUNCIONAR)
kubectl run test-specific --image=nginx:1.25.3 -n tienda-online
kubectl delete pod test-specific -n tienda-online
```

### Probar Política 2: Resource Limits

```bash
# ❌ Intentar desplegar sin límites (debe FALLAR)
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: test-no-limits
  namespace: tienda-online
spec:
  containers:
  - name: test
    image: nginx:1.25.3
EOF

# Resultado esperado:
# Error from server: admission webhook denied the request...
# require-resource-limits: validation error: Todos los contenedores deben tener...

# ✅ Desplegar con límites (debe FUNCIONAR)
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: test-with-limits
  namespace: tienda-online
spec:
  containers:
  - name: test
    image: nginx:1.25.3
    resources:
      requests:
        cpu: "100m"
        memory: "128Mi"
      limits:
        cpu: "200m"
        memory: "256Mi"
EOF

kubectl delete pod test-with-limits -n tienda-online
```

### Probar Política 3: No Root

```bash
# ❌ Intentar desplegar sin securityContext (debe FALLAR)
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: test-root
  namespace: tienda-online
spec:
  containers:
  - name: test
    image: nginx:1.25.3
EOF

# Resultado esperado:
# Error from server: admission webhook denied the request...
# disallow-root-user: validation error: Los contenedores deben ejecutarse como usuario no-root...

# ✅ Desplegar como non-root (debe FUNCIONAR)
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: test-nonroot
  namespace: tienda-online
spec:
  securityContext:
    runAsNonRoot: true
  containers:
  - name: test
    image: nginx:1.25.3-alpine
    securityContext:
      runAsNonRoot: true
      runAsUser: 1001
      allowPrivilegeEscalation: false
EOF

kubectl delete pod test-nonroot -n tienda-online --ignore-not-found
```

### Probar Política 4: Require Labels

```bash
# ❌ Intentar desplegar sin etiquetas estándar (debe FALLAR)
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: test-no-labels
  namespace: tienda-online
  labels:
    app: test
spec:
  containers:
  - name: test
    image: nginx:1.25.3
EOF

# Resultado esperado:
# Error from server: admission webhook denied the request...
# require-labels: validation error: El recurso debe tener la etiqueta 'app.kubernetes.io/name'...

# ✅ Desplegar con etiquetas estándar (debe FUNCIONAR)
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: test-with-labels
  namespace: tienda-online
  labels:
    app.kubernetes.io/name: test-app
    app.kubernetes.io/version: "1.0.0"
    app.kubernetes.io/component: test
    app.kubernetes.io/managed-by: kubectl
spec:
  securityContext:
    runAsNonRoot: true
  containers:
  - name: test
    image: nginx:1.25.3-alpine
    securityContext:
      runAsNonRoot: true
      runAsUser: 1001
      allowPrivilegeEscalation: false
    resources:
      requests:
        cpu: "50m"
        memory: "64Mi"
      limits:
        cpu: "100m"
        memory: "128Mi"
EOF

kubectl delete pod test-with-labels -n tienda-online
```

## 📊 Reportes de Políticas

### Ver violaciones de políticas

```bash
# Ver reportes de políticas en todos los namespaces
kubectl get policyreport -A

# Ver detalles de un reporte específico
kubectl describe policyreport -n tienda-online

# Ver violaciones en formato YAML
kubectl get policyreport -n tienda-online -o yaml

# Ver solo políticas que han fallado
kubectl get policyreport -A -o json | jq '.items[] | select(.summary.fail > 0)'
```

### Ver eventos de Kyverno

```bash
# Ver eventos relacionados con Kyverno
kubectl get events -n tienda-online --field-selector source=kyverno

# Ver logs de Kyverno
kubectl logs -n kyverno -l app.kubernetes.io/name=kyverno -f
```

## 🔧 Troubleshooting

### Política no se aplica

```bash
# Verificar que la política esté instalada
kubectl get clusterpolicy

# Ver detalles y estado de la política
kubectl describe clusterpolicy disallow-latest-tag

# Verificar que Kyverno esté corriendo
kubectl get pods -n kyverno

# Ver logs de Kyverno
kubectl logs -n kyverno -l app.kubernetes.io/name=kyverno --tail=100
```

### Política bloquea despliegue legítimo

Si necesitas temporalmente deshabilitar una política:

```bash
# Cambiar de Enforce a Audit (solo reporta, no bloquea)
kubectl patch clusterpolicy disallow-latest-tag --type='json' \
  -p='[{"op": "replace", "path": "/spec/validationFailureAction", "value":"Audit"}]'

# Volver a Enforce
kubectl patch clusterpolicy disallow-latest-tag --type='json' \
  -p='[{"op": "replace", "path": "/spec/validationFailureAction", "value":"Enforce"}]'
```

### Excluir un namespace de las políticas

```yaml
# Agregar exclusión en la política
spec:
  rules:
  - name: require-image-tag
    match:
      any:
      - resources:
          kinds:
            - Pod
    exclude:
      any:
      - resources:
          namespaces:
            - kube-system
            - kyverno
```

## 📈 Métricas

Kyverno expone métricas de Prometheus en el puerto 8000:

```bash
# Port forward
kubectl port-forward -n kyverno svc/kyverno-svc-metrics 8000:8000

# Ver métricas
curl http://localhost:8000/metrics | grep kyverno
```

Métricas importantes:
- `kyverno_policy_results_total`: Total de resultados de políticas
- `kyverno_admission_requests_total`: Total de admission requests
- `kyverno_policy_rule_execution_duration_seconds`: Duración de ejecución de reglas

## 🧹 Desinstalación

```bash
# Eliminar todas las políticas
kubectl delete -f k8s/kyverno/

# O una por una
kubectl delete clusterpolicy disallow-latest-tag
kubectl delete clusterpolicy require-resource-limits
kubectl delete clusterpolicy disallow-root-user
kubectl delete clusterpolicy require-labels

# Desinstalar Kyverno
helm uninstall kyverno -n kyverno
kubectl delete namespace kyverno

# Eliminar CRDs
kubectl delete crd clusterpolicies.kyverno.io
kubectl delete crd clusterpolicyreports.wgpolicyk8s.io
kubectl delete crd policyreports.wgpolicyk8s.io
```

## 📚 Referencias

- [Kyverno Documentation](https://kyverno.io/docs/)
- [Kyverno Policies](https://kyverno.io/policies/)
- [Kubernetes Recommended Labels](https://kubernetes.io/docs/concepts/overview/working-with-objects/common-labels/)
- [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
- [OWASP Kubernetes Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Kubernetes_Security_Cheat_Sheet.html)

## 🎯 Próximos Pasos

1. ✅ Políticas creadas y documentadas
2. ⏳ Instalar Kyverno en el cluster
3. ⏳ Aplicar y probar cada política
4. ⏳ Validar que el Helm Chart cumple con todas las políticas
5. ⏳ Generar reporte de validación
6. ⏳ Integrar validación en el pipeline de CI/CD

