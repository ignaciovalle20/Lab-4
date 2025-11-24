#!/bin/bash

# cleanup.sh - Script para limpiar todos los recursos del proyecto
# Este script elimina todos los componentes desplegados

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Banner
print_header "            LIMPIEZA COMPLETA - TIENDA ONLINE              "
echo ""

# Confirmación
print_warning "Este script eliminará TODOS los recursos del proyecto:"
echo ""
echo "  - Aplicación Tienda Online"
echo "  - Prometheus y Grafana"
echo "  - Kyverno y sus políticas"
echo "  - Falco"
echo "  - Todos los namespaces y PVCs"
echo ""
read -p "¿Estás seguro? (escribe 'SI' para continuar): " CONFIRM

if [ "$CONFIRM" != "SI" ]; then
    print_warning "Limpieza cancelada"
    exit 0
fi

echo ""

# 1. Desinstalar aplicación
print_header "PASO 1: Desinstalando aplicación Tienda Online"
echo ""

if helm list -n tienda-online | grep -q tienda-online; then
    print_step "Desinstalando Helm release..."
    helm uninstall tienda-online -n tienda-online
    print_success "Aplicación desinstalada"
else
    print_warning "Aplicación no está instalada"
fi
echo ""

# 2. Desinstalar Prometheus y Grafana
print_header "PASO 2: Desinstalando Prometheus y Grafana"
echo ""

if helm list -n monitoring | grep -q prometheus; then
    print_step "Desinstalando Prometheus stack..."
    helm uninstall prometheus -n monitoring
    print_success "Prometheus desinstalado"
else
    print_warning "Prometheus no está instalado"
fi
echo ""

# Eliminar CRDs de Prometheus
print_step "Eliminando CRDs de Prometheus..."
kubectl delete crd alertmanagerconfigs.monitoring.coreos.com 2>/dev/null || true
kubectl delete crd alertmanagers.monitoring.coreos.com 2>/dev/null || true
kubectl delete crd podmonitors.monitoring.coreos.com 2>/dev/null || true
kubectl delete crd probes.monitoring.coreos.com 2>/dev/null || true
kubectl delete crd prometheuses.monitoring.coreos.com 2>/dev/null || true
kubectl delete crd prometheusrules.monitoring.coreos.com 2>/dev/null || true
kubectl delete crd servicemonitors.monitoring.coreos.com 2>/dev/null || true
kubectl delete crd thanosrulers.monitoring.coreos.com 2>/dev/null || true
print_success "CRDs eliminados"
echo ""

# 3. Desinstalar Kyverno
print_header "PASO 3: Desinstalando Kyverno"
echo ""

# Eliminar políticas primero
print_step "Eliminando políticas de Kyverno..."
kubectl delete -f k8s/kyverno/ 2>/dev/null || true
print_success "Políticas eliminadas"
echo ""

if helm list -n kyverno | grep -q kyverno; then
    print_step "Desinstalando Kyverno..."
    helm uninstall kyverno -n kyverno
    print_success "Kyverno desinstalado"
else
    print_warning "Kyverno no está instalado"
fi
echo ""

# Eliminar CRDs de Kyverno
print_step "Eliminando CRDs de Kyverno..."
kubectl delete crd clusterpolicies.kyverno.io 2>/dev/null || true
kubectl delete crd clusterpolicyreports.wgpolicyk8s.io 2>/dev/null || true
kubectl delete crd policyreports.wgpolicyk8s.io 2>/dev/null || true
kubectl delete crd policies.kyverno.io 2>/dev/null || true
kubectl delete crd policyexceptions.kyverno.io 2>/dev/null || true
kubectl delete crd updaterequests.kyverno.io 2>/dev/null || true
kubectl delete crd admissionreports.kyverno.io 2>/dev/null || true
kubectl delete crd backgroundscanreports.kyverno.io 2>/dev/null || true
kubectl delete crd clusteradmissionreports.kyverno.io 2>/dev/null || true
kubectl delete crd clusterbackgroundscanreports.kyverno.io 2>/dev/null || true
print_success "CRDs eliminados"
echo ""

# 4. Desinstalar Falco
print_header "PASO 4: Desinstalando Falco"
echo ""

if helm list -n falco | grep -q falco; then
    print_step "Desinstalando Falco..."
    helm uninstall falco -n falco
    print_success "Falco desinstalado"
else
    print_warning "Falco no está instalado"
fi
echo ""

# 5. Eliminar namespaces
print_header "PASO 5: Eliminando namespaces"
echo ""

NAMESPACES=("tienda-online" "monitoring" "kyverno" "falco")

for ns in "${NAMESPACES[@]}"; do
    if kubectl get namespace $ns &> /dev/null; then
        print_step "Eliminando namespace $ns..."
        kubectl delete namespace $ns --timeout=60s || true
        print_success "Namespace $ns eliminado"
    else
        print_warning "Namespace $ns no existe"
    fi
done
echo ""

# 6. Limpiar PVCs huérfanos
print_header "PASO 6: Limpiando PVCs huérfanos"
echo ""

print_step "Buscando PVCs huérfanos..."
ORPHAN_PVCS=$(kubectl get pvc --all-namespaces 2>/dev/null | grep -E "tienda-|prometheus-|grafana-" | awk '{print $2}' || true)

if [ -n "$ORPHAN_PVCS" ]; then
    echo "$ORPHAN_PVCS" | while read pvc; do
        print_step "Eliminando PVC: $pvc"
        kubectl delete pvc $pvc --all-namespaces 2>/dev/null || true
    done
    print_success "PVCs huérfanos eliminados"
else
    print_success "No hay PVCs huérfanos"
fi
echo ""

# 7. Limpiar imágenes Docker (opcional)
print_header "PASO 7: Limpieza de imágenes Docker"
echo ""

read -p "¿Deseas eliminar las imágenes Docker del proyecto? (y/N): " CLEANUP_IMAGES

if [[ "$CLEANUP_IMAGES" =~ ^[Yy]$ ]]; then
    print_step "Configurando Docker para usar daemon de Minikube..."
    eval $(minikube docker-env)
    
    print_step "Eliminando imágenes de la aplicación..."
    docker rmi tienda-backend:lab4 2>/dev/null || true
    docker rmi tienda-frontend:lab4 2>/dev/null || true
    docker rmi tienda-database:lab4 2>/dev/null || true
    print_success "Imágenes eliminadas"
else
    print_warning "Imágenes Docker no eliminadas"
fi
echo ""

# 8. Detener Minikube (opcional)
print_header "PASO 8: Detener Minikube"
echo ""

read -p "¿Deseas detener Minikube? (y/N): " STOP_MINIKUBE

if [[ "$STOP_MINIKUBE" =~ ^[Yy]$ ]]; then
    print_step "Deteniendo Minikube..."
    minikube stop
    print_success "Minikube detenido"
    
    read -p "¿Deseas ELIMINAR el cluster de Minikube completamente? (y/N): " DELETE_MINIKUBE
    
    if [[ "$DELETE_MINIKUBE" =~ ^[Yy]$ ]]; then
        print_warning "Eliminando cluster de Minikube..."
        minikube delete
        print_success "Cluster de Minikube eliminado"
    fi
else
    print_warning "Minikube sigue corriendo"
fi
echo ""

# 9. Resumen
print_header "RESUMEN DE LIMPIEZA"
echo ""

print_success "Limpieza completada exitosamente"
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "                    RECURSOS ELIMINADOS                     "
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "✓ Aplicación Tienda Online"
echo "✓ Prometheus y Grafana"
echo "✓ Kyverno y políticas"
echo "✓ Falco"
echo "✓ Namespaces: tienda-online, monitoring, kyverno, falco"
echo "✓ PVCs y PVs asociados"

if [[ "$CLEANUP_IMAGES" =~ ^[Yy]$ ]]; then
    echo "✓ Imágenes Docker de la aplicación"
fi

if [[ "$STOP_MINIKUBE" =~ ^[Yy]$ ]]; then
    echo "✓ Minikube detenido"
fi

if [[ "$DELETE_MINIKUBE" =~ ^[Yy]$ ]]; then
    echo "✓ Cluster de Minikube eliminado"
fi
echo ""
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "💡 PRÓXIMOS PASOS:"
echo ""
echo "Para volver a desplegar todo desde cero:"
echo "   ./scripts/init.sh"
echo ""
echo "Para iniciar solo Minikube:"
echo "   minikube start"
echo ""
print_success "Limpieza finalizada ✨"
echo ""

