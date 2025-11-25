#!/bin/bash

# init.sh - Script de inicialización completa del proyecto Tienda Online
# Este script automatiza el despliegue de toda la infraestructura y aplicación
#
# Uso:
#   ./scripts/init.sh                    # Ejecuta todos los pasos
#   ENABLE_STEP_1=false ./scripts/init.sh # Deshabilita el paso 1
#   ENABLE_STEP_3=false ENABLE_STEP_5=false ./scripts/init.sh # Deshabilita pasos 3 y 5
#
# Variables de entorno para habilitar/deshabilitar pasos:
#   ENABLE_STEP_1=true|false  # Verificar prerequisitos (default: true)
#   ENABLE_STEP_2=true|false  # Inicializar Minikube (default: true)
#   ENABLE_STEP_3=true|false  # Construir imágenes Docker (default: true)
#   ENABLE_STEP_4=true|false  # Crear namespaces (default: true)
#   ENABLE_STEP_5=true|false  # Instalar Prometheus y Grafana (default: true)
#   ENABLE_STEP_6=true|false  # Instalar Kyverno (default: false)
#   ENABLE_STEP_7=true|false  # Instalar Falco (default: false)
#   ENABLE_STEP_8=true|false  # Desplegar aplicación (default: true)
#   ENABLE_STEP_9=true|false  # Verificar estado (default: true)
#   ENABLE_STEP_10=true|false # Información de acceso (default: true)

set -e  # Exit on error

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuración de pasos (valores por defecto)
ENABLE_STEP_1=${ENABLE_STEP_1:-true}
ENABLE_STEP_2=${ENABLE_STEP_2:-true}
ENABLE_STEP_3=${ENABLE_STEP_3:-true}
ENABLE_STEP_4=${ENABLE_STEP_4:-true}
ENABLE_STEP_5=${ENABLE_STEP_5:-true}
ENABLE_STEP_6=${ENABLE_STEP_6:-false}
ENABLE_STEP_7=${ENABLE_STEP_7:-false}
ENABLE_STEP_8=${ENABLE_STEP_8:-true}
ENABLE_STEP_9=${ENABLE_STEP_9:-true}
ENABLE_STEP_10=${ENABLE_STEP_10:-true}

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

print_skipped() {
    echo -e "${YELLOW}⊘${NC} $1 (omitido)"
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
    # Esperar solo pods que no estén en estado Completed o Failed (excluir Jobs completados)
    # Iterar sobre cada pod y esperar solo los que están Running o Pending
    for pod in $(kubectl get pods -n $namespace -o jsonpath='{.items[*].metadata.name}'); do
        phase=$(kubectl get pod $pod -n $namespace -o jsonpath='{.status.phase}' 2>/dev/null || echo "Unknown")
        if [ "$phase" != "Succeeded" ] && [ "$phase" != "Failed" ]; then
            kubectl wait --for=condition=ready pod/$pod -n $namespace --timeout=${timeout}s 2>/dev/null || true
        fi
    done
    echo ""
}

force_delete_namespace() {
    local namespace=$1
    local max_wait=${2:-60}
    
    # Verificar si el namespace existe
    if ! kubectl get namespace "$namespace" &>/dev/null; then
        return 0
    fi
    
    # Verificar si está en estado Terminating
    local phase=$(kubectl get namespace "$namespace" -o jsonpath='{.status.phase}' 2>/dev/null || echo "")
    
    if [ "$phase" = "Terminating" ]; then
        print_warning "Namespace '$namespace' está en estado Terminating, forzando eliminación..."
        
        # Remover finalizers para forzar la eliminación
        kubectl get namespace "$namespace" -o json | \
            jq '.spec.finalizers = []' | \
            kubectl replace --raw "/api/v1/namespaces/$namespace/finalize" -f - &>/dev/null || \
        kubectl patch namespace "$namespace" -p '{"metadata":{"finalizers":[]}}' --type=merge &>/dev/null || true
        
        # Esperar a que termine de eliminarse
        print_step "Esperando a que el namespace '$namespace' termine de eliminarse (máximo ${max_wait}s)..."
        local elapsed=0
        while [ $elapsed -lt $max_wait ]; do
            if ! kubectl get namespace "$namespace" &>/dev/null; then
                print_success "Namespace '$namespace' eliminado correctamente"
                return 0
            fi
            sleep 2
            elapsed=$((elapsed + 2))
        done
        
        # Si aún existe después del timeout, intentar otra vez
        if kubectl get namespace "$namespace" &>/dev/null; then
            print_warning "Namespace '$namespace' aún existe después de ${max_wait}s, intentando forzar nuevamente..."
            kubectl delete namespace "$namespace" --grace-period=0 --force &>/dev/null || true
            sleep 5
        fi
    fi
    
    return 0
}

# Función para ejecutar un paso si está habilitado
run_step() {
    local step_num=$1
    local step_name=$2
    local step_func=$3
    local enable_var="ENABLE_STEP_${step_num}"
    
    # Obtener el valor de la variable de entorno
    local enabled=$(eval echo \$$enable_var)
    
    if [ "$enabled" = "true" ]; then
        print_header "PASO ${step_num}: ${step_name}"
        echo ""
        $step_func
    else
        print_skipped "PASO ${step_num}: ${step_name}"
        echo ""
    fi
}

# Funciones de pasos
step_1_verify_prerequisites() {
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
}

step_2_init_minikube() {
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
}

step_3_build_docker_images() {
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
}

step_4_create_namespaces() {
    kubectl create namespace tienda-online --dry-run=client -o yaml | kubectl apply -f -
    print_success "Namespace 'tienda-online' creado"

    kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
    print_success "Namespace 'monitoring' creado"

    kubectl create namespace kyverno --dry-run=client -o yaml | kubectl apply -f -
    print_success "Namespace 'kyverno' creado"

    kubectl create namespace falco --dry-run=client -o yaml | kubectl apply -f -
    print_success "Namespace 'falco' creado"
    echo ""
}

step_5_install_prometheus_grafana() {
    print_step "Creando ConfigMap de Grafana dashboards..."
    kubectl apply -f k8s/monitoring/grafana-dashboard-configmap.yaml
    print_success "ConfigMap creado"
    echo ""

    print_step "Agregando repositorio de Prometheus..."
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>/dev/null || true
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
}

step_6_install_kyverno() {
    print_step "Agregando repositorio de Kyverno..."
    helm repo add kyverno https://kyverno.github.io/kyverno/ 2>/dev/null || true
    helm repo update
    print_success "Repositorio agregado"
    echo ""

    print_step "Instalando Kyverno..."
    if helm list -n kyverno | grep -q kyverno; then
        print_warning "Kyverno ya está instalado, actualizando..."
        helm upgrade kyverno kyverno/kyverno \
            -n kyverno \
            -f k8s/kyverno/values.yaml \
            --wait --timeout=5m
    else
        helm install kyverno kyverno/kyverno \
            -n kyverno \
            -f k8s/kyverno/values.yaml \
            --wait --timeout=5m
    fi
    print_success "Kyverno instalado"
    echo ""

    wait_for_pods kyverno 300

    print_step "Aplicando políticas de Kyverno..."
    # Aplicar solo los archivos de políticas, excluyendo values.yaml y README.md
    kubectl apply -f k8s/kyverno/no-latest-tag.yaml
    kubectl apply -f k8s/kyverno/no-root.yaml
    kubectl apply -f k8s/kyverno/require-labels.yaml
    kubectl apply -f k8s/kyverno/require-limits.yaml
    print_success "Políticas aplicadas"
    echo ""
}

step_7_install_falco() {
    print_step "Agregando repositorio de Falco..."
    helm repo add falcosecurity https://falcosecurity.github.io/charts 2>/dev/null || true
    helm repo update
    print_success "Repositorio agregado"
    echo ""

    print_step "Instalando Falco..."
    if helm list -n falco | grep -q falco; then
        print_warning "Falco ya está instalado, actualizando..."
        helm upgrade falco falcosecurity/falco \
            -n falco \
            -f k8s/falco/values.yaml \
            --wait --timeout=5m
    else
        helm install falco falcosecurity/falco \
            -n falco \
            -f k8s/falco/values.yaml \
            --wait --timeout=5m
    fi
    print_success "Falco instalado"
    echo ""

    # Nota: El ConfigMap de reglas personalizadas se maneja en values.yaml de Falco
    # Si existe el archivo custom-rules.yaml, intentar aplicarlo
    if [ -f "k8s/falco/custom-rules.yaml" ]; then
        print_step "Aplicando reglas personalizadas de Falco..."
        kubectl create configmap falco-custom-rules \
            --from-file=custom-rules.yaml=k8s/falco/custom-rules.yaml \
            -n falco \
            --dry-run=client -o yaml | kubectl apply -f -
        print_success "Reglas personalizadas aplicadas (ConfigMap creado)"
        print_step "Las reglas se cargarán automáticamente desde el ConfigMap montado"
        echo ""
    fi

    wait_for_pods falco 300
    echo ""
}

step_8_deploy_application() {
    print_step "Desplegando con Helm..."
    if helm list -n tienda-online | grep -q tienda-online; then
        print_warning "Aplicación ya está desplegada, actualizando..."
        helm upgrade tienda-online ./helm-chart/tienda-online \
            -n tienda-online \
            -f helm-chart/tienda-online/values.yaml
    else
        helm install tienda-online ./helm-chart/tienda-online \
            -n tienda-online \
            -f helm-chart/tienda-online/values.yaml \
            --wait --timeout=5m
    fi
    print_success "Aplicación desplegada"
    echo ""

    wait_for_pods tienda-online 300

    # Aplicar ServiceMonitor
    print_step "Aplicando ServiceMonitor de Prometheus..."
    kubectl apply -f k8s/monitoring/servicemonitor.yaml
    print_success "ServiceMonitor aplicado"
    echo ""
}

step_9_verify_status() {
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
}

step_10_show_access_info() {
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
    echo "   Port forward: kubectl port-forward -n tienda-online svc/backend-service 5000:5000"
    echo "   URL: http://localhost:5000"
    echo "   Swagger: http://localhost:5000/api-docs"
    echo "   Métricas: http://localhost:5000/metrics"
    echo ""
    echo "🖥️  FRONTEND:"
    echo "   Port forward: kubectl port-forward -n tienda-online svc/frontend-service 3001:80"
    echo "   URL: http://localhost:3001"
    echo ""
    echo "🗄️  DATABASE:"
    echo "   Port forward: kubectl port-forward -n tienda-online svc/mysql-service 3306:3306"
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
}

# Banner
print_header "                 TIENDA ONLINE - LAB 4                      "
echo ""
print_step "Inicializando infraestructura completa..."
echo ""

# Mostrar configuración de pasos
print_step "Configuración de pasos:"
echo "  Paso 1 (Verificar prerequisitos): $ENABLE_STEP_1"
echo "  Paso 2 (Inicializar Minikube): $ENABLE_STEP_2"
echo "  Paso 3 (Construir imágenes Docker): $ENABLE_STEP_3"
echo "  Paso 4 (Crear namespaces): $ENABLE_STEP_4"
echo "  Paso 5 (Instalar Prometheus/Grafana): $ENABLE_STEP_5"
echo "  Paso 6 (Instalar Kyverno): $ENABLE_STEP_6"
echo "  Paso 7 (Instalar Falco): $ENABLE_STEP_7"
echo "  Paso 8 (Desplegar aplicación): $ENABLE_STEP_8"
echo "  Paso 9 (Verificar estado): $ENABLE_STEP_9"
echo "  Paso 10 (Información de acceso): $ENABLE_STEP_10"
echo ""

# Ejecutar pasos
run_step 1 "Verificando prerequisitos" step_1_verify_prerequisites
run_step 2 "Inicializando Minikube" step_2_init_minikube
run_step 3 "Construyendo imágenes Docker" step_3_build_docker_images
run_step 4 "Creando namespaces" step_4_create_namespaces
run_step 5 "Instalando Prometheus y Grafana" step_5_install_prometheus_grafana
run_step 6 "Instalando Kyverno" step_6_install_kyverno
run_step 7 "Instalando Falco" step_7_install_falco
run_step 8 "Desplegando aplicación Tienda Online" step_8_deploy_application
run_step 9 "Verificando estado del cluster" step_9_verify_status
run_step 10 "Información de acceso" step_10_show_access_info

