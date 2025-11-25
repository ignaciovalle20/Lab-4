#!/bin/bash

# init.sh - Script de inicialización completa del proyecto Tienda Online
# Este script automatiza el despliegue de toda la infraestructura y aplicación

set -e  # Exit on error

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funciones de utilidad
print_header() {
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║ $1${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
}

print_step() {
    echo -e "${GREEN}➜${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC}  $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

check_command() {
    if command -v $1 &> /dev/null; then
        print_success "$1 está instalado"
        return 0
    else
        print_error "$1 no está instalado"
        return 1
    fi
}

wait_for_pods() {
    local namespace=$1
    local timeout=${2:-300}
    print_step "Esperando a que los pods en namespace '$namespace' estén listos (timeout: ${timeout}s)..."
    kubectl wait --for=condition=ready pod --all -n $namespace --timeout=${timeout}s || true
    echo ""
}

# Banner
print_header "                 TIENDA ONLINE - LAB 4                      "
echo ""
print_step "Inicializando infraestructura completa..."
echo ""

# 1. Verificar prerequisitos
print_header "PASO 1: Verificando prerequisitos"
echo ""

MISSING_DEPS=false

check_command docker || MISSING_DEPS=true
check_command kubectl || MISSING_DEPS=true
check_command helm || MISSING_DEPS=true
check_command minikube || MISSING_DEPS=true

echo ""

if [ "$MISSING_DEPS" = true ]; then
    print_error "Faltan dependencias requeridas. Por favor, instala las herramientas faltantes."
    echo ""
    echo "Guía de instalación:"
    echo "  - Docker: https://docs.docker.com/get-docker/"
    echo "  - kubectl: https://kubernetes.io/docs/tasks/tools/"
    echo "  - Helm: https://helm.sh/docs/intro/install/"
    echo "  - Minikube: https://minikube.sigs.k8s.io/docs/start/"
    exit 1
fi

print_success "Todos los prerequisitos están instalados"
echo ""

# 2. Iniciar Minikube
print_header "PASO 2: Inicializando Minikube"
echo ""

if minikube status | grep -q "Running"; then
    print_success "Minikube ya está corriendo"
else
    print_step "Iniciando Minikube..."
    minikube start --driver=docker --cpus=4 --memory=8192 --disk-size=20g
    print_success "Minikube iniciado correctamente"
fi

# Configurar kubectl context
kubectl config use-context minikube
print_success "Contexto de kubectl configurado a minikube"
echo ""

# 3. Construir imágenes Docker
print_header "PASO 3: Construyendo imágenes Docker"
echo ""

# Configurar Docker para usar el daemon de Minikube
print_step "Configurando Docker para usar el daemon de Minikube..."
eval $(minikube docker-env)
print_success "Docker configurado para Minikube"
echo ""

# Backend
print_step "Construyendo imagen del backend..."
docker build -t tienda-backend:lab4 ./backend
print_success "Imagen tienda-backend:lab4 construida"
echo ""

# Frontend
print_step "Construyendo imagen del frontend..."
docker build -t tienda-frontend:lab4 ./frontend
print_success "Imagen tienda-frontend:lab4 construida"
echo ""

# Database
print_step "Construyendo imagen de la base de datos..."
docker build -t tienda-database:lab4 ./database
print_success "Imagen tienda-database:lab4 construida"
echo ""

# 4. Crear namespaces
print_header "PASO 4: Creando namespaces"
echo ""

kubectl create namespace tienda-online --dry-run=client -o yaml | kubectl apply -f -
print_success "Namespace 'tienda-online' creado"

kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
print_success "Namespace 'monitoring' creado"

kubectl create namespace kyverno --dry-run=client -o yaml | kubectl apply -f -
print_success "Namespace 'kyverno' creado"

kubectl create namespace falco --dry-run=client -o yaml | kubectl apply -f -
print_success "Namespace 'falco' creado"
echo ""

# 5. Instalar Prometheus y Grafana
print_header "PASO 5: Instalando Prometheus y Grafana"
echo ""

print_step "Creando ConfigMap de Grafana dashboards..."
kubectl apply -f k8s/monitoring/grafana-dashboard-configmap.yaml
print_success "ConfigMap creado"
echo ""

print_step "Agregando repositorio de Prometheus..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
print_success "Repositorio agregado"
echo ""

print_step "Instalando kube-prometheus-stack..."
if helm list -n monitoring | grep -q prometheus; then
    # Verificar si el release está en estado failed
    if helm list -n monitoring | grep prometheus | grep -q failed; then
        print_warning "Release de Prometheus en estado failed, eliminando para reinstalar..."
        helm uninstall prometheus -n monitoring || true
        sleep 2
        helm install prometheus prometheus-community/kube-prometheus-stack \
            -n monitoring \
            -f k8s/monitoring/prometheus-values.yaml \
            --wait --timeout=5m
    else
        print_warning "Prometheus ya está instalado, actualizando..."
        helm upgrade prometheus prometheus-community/kube-prometheus-stack \
            -n monitoring \
            -f k8s/monitoring/prometheus-values.yaml \
            --wait --timeout=5m
    fi
else
    helm install prometheus prometheus-community/kube-prometheus-stack \
        -n monitoring \
        -f k8s/monitoring/prometheus-values.yaml
fi
print_success "Prometheus y Grafana instalados"
echo ""

wait_for_pods monitoring 300

# 6. Instalar Kyverno
print_header "PASO 6: Instalando Kyverno"
echo ""

print_step "Agregando repositorio de Kyverno..."
helm repo add kyverno https://kyverno.github.io/kyverno/
helm repo update
print_success "Repositorio agregado"
echo ""

print_step "Instalando Kyverno..."
if helm list -n kyverno | grep -q kyverno; then
    print_warning "Kyverno ya está instalado, actualizando..."
    helm upgrade kyverno kyverno/kyverno -n kyverno
else
    helm install kyverno kyverno/kyverno \
        -n kyverno \
        --wait --timeout=5m
fi
print_success "Kyverno instalado"
echo ""

wait_for_pods kyverno 300

print_step "Aplicando políticas de Kyverno..."
kubectl apply -f k8s/kyverno/
print_success "Políticas aplicadas"
echo ""

# 7. Instalar Falco
print_header "PASO 7: Instalando Falco"
echo ""

print_step "Agregando repositorio de Falco..."
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm repo update
print_success "Repositorio agregado"
echo ""

print_step "Instalando Falco..."
if helm list -n falco | grep -q falco; then
    print_warning "Falco ya está instalado, actualizando..."
    helm upgrade falco falcosecurity/falco -n falco
else
    helm install falco falcosecurity/falco \
        -n falco \
        --set tty=true \
        --set driver.kind=modern_ebpf \
        --set falco.grpc.enabled=true \
        --set falco.grpc_output.enabled=true \
        --set falco.json_output=true \
        --set falco.log_stderr=true \
        --set falco.log_syslog=false \
        --set falco.log_level=info \
        --set falco.priority=debug \
        --wait --timeout=5m
fi
print_success "Falco instalado"
echo ""

wait_for_pods falco 300

# 8. Desplegar aplicación
print_header "PASO 8: Desplegando aplicación Tienda Online"
echo ""

print_step "Desplegando con Helm..."
if helm list -n tienda-online | grep -q tienda-online; then
    print_warning "Aplicación ya está desplegada, actualizando..."
    helm upgrade tienda-online ./helm-chart/tienda-online \
        -n tienda-online \
        -f helm-chart/tienda-online/values-dev.yaml
else
    helm install tienda-online ./helm-chart/tienda-online \
        -n tienda-online \
        -f helm-chart/tienda-online/values-dev.yaml \
        --wait --timeout=5m
fi
print_success "Aplicación desplegada"
echo ""

wait_for_pods tienda-online 300

# 9. Aplicar ServiceMonitor
print_step "Aplicando ServiceMonitor de Prometheus..."
kubectl apply -f k8s/monitoring/servicemonitor.yaml
print_success "ServiceMonitor aplicado"
echo ""

# 10. Verificar estado
print_header "PASO 9: Verificando estado del cluster"
echo ""

print_step "Estado de los pods:"
echo ""
echo "Namespace: monitoring"
kubectl get pods -n monitoring
echo ""
echo "Namespace: kyverno"
kubectl get pods -n kyverno
echo ""
echo "Namespace: falco"
kubectl get pods -n falco
echo ""
echo "Namespace: tienda-online"
kubectl get pods -n tienda-online
echo ""

print_step "Estado de los servicios:"
echo ""
kubectl get svc -n tienda-online
echo ""

# 11. Información de acceso
print_header "PASO 10: Información de acceso"
echo ""

print_success "¡Despliegue completado exitosamente!"
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "                    INFORMACIÓN DE ACCESO                   "
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "📊 GRAFANA:"
echo "   Port forward: kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80"
echo "   URL: http://localhost:3000"
echo "   Usuario: admin"
echo "   Password: admin123"
echo ""
echo "📈 PROMETHEUS:"
echo "   Port forward: kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090"
echo "   URL: http://localhost:9090"
echo ""
echo "🛒 BACKEND (API):"
echo "   Port forward: kubectl port-forward -n tienda-online svc/tienda-backend 5000:5000"
echo "   URL: http://localhost:5000"
echo "   Swagger: http://localhost:5000/api-docs"
echo "   Métricas: http://localhost:5000/metrics"
echo ""
echo "🖥️  FRONTEND:"
echo "   Port forward: kubectl port-forward -n tienda-online svc/tienda-frontend 3001:80"
echo "   URL: http://localhost:3001"
echo ""
echo "🗄️  DATABASE:"
echo "   Port forward: kubectl port-forward -n tienda-online svc/tienda-database 3306:3306"
echo "   Host: localhost:3306"
echo "   Usuario: tienda_user"
echo "   Password: tienda_pass"
echo "   Database: tienda_online"
echo ""
echo "🔒 KYVERNO:"
echo "   Ver políticas: kubectl get clusterpolicies"
echo "   Ver reportes: kubectl get policyreport -A"
echo ""
echo "🛡️  FALCO:"
echo "   Ver logs: kubectl logs -n falco -l app.kubernetes.io/name=falco -f"
echo ""
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "💡 PRÓXIMOS PASOS:"
echo ""
echo "1. Poblar la base de datos con datos de prueba:"
echo "   ./scripts/populate.sh"
echo ""
echo "2. Generar tráfico para métricas:"
echo "   ./scripts/generate-traffic.sh"
echo ""
echo "3. Ver logs de Falco:"
echo "   kubectl logs -n falco -l app.kubernetes.io/name=falco --tail=50"
echo ""
echo "4. Acceder a Grafana y ver el dashboard"
echo ""
echo "5. Para limpiar todo:"
echo "   ./scripts/cleanup.sh"
echo ""
print_success "Inicialización completada ✨"
echo ""

