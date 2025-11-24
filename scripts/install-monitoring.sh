#!/bin/bash

# Script para instalar Prometheus y Grafana en Kubernetes
# Uso: ./scripts/install-monitoring.sh

set -e

# Colores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Instalación de Prometheus y Grafana${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Verificar si kubectl está instalado
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}❌ kubectl no está instalado${NC}"
    exit 1
fi

# Verificar si helm está instalado
if ! command -v helm &> /dev/null; then
    echo -e "${RED}❌ helm no está instalado${NC}"
    exit 1
fi

# Verificar si minikube está corriendo
echo -e "${YELLOW}Verificando Minikube...${NC}"
if ! kubectl get nodes &> /dev/null; then
    echo -e "${RED}❌ Minikube no está corriendo${NC}"
    echo -e "${YELLOW}Iniciando Minikube...${NC}"
    minikube start
else
    echo -e "${GREEN}✓ Minikube está corriendo${NC}"
fi
echo ""

# Crear namespace para monitoreo
echo -e "${YELLOW}Creando namespace 'monitoring'...${NC}"
if kubectl get namespace monitoring &> /dev/null; then
    echo -e "${GREEN}✓ Namespace 'monitoring' ya existe${NC}"
else
    kubectl create namespace monitoring
    echo -e "${GREEN}✓ Namespace 'monitoring' creado${NC}"
fi
echo ""

# Agregar repositorio de Helm
echo -e "${YELLOW}Agregando repositorio de Helm...${NC}"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>/dev/null || true
helm repo update
echo -e "${GREEN}✓ Repositorio agregado y actualizado${NC}\n"

# Instalar kube-prometheus-stack
echo -e "${YELLOW}Instalando kube-prometheus-stack...${NC}"
echo -e "${BLUE}Esto puede tomar varios minutos...${NC}\n"

if helm list -n monitoring | grep -q prometheus; then
    echo -e "${YELLOW}⚠️  kube-prometheus-stack ya está instalado${NC}"
    echo -e "${YELLOW}¿Deseas actualizar? (s/n)${NC}"
    read -r response
    if [[ "$response" =~ ^([sS][iI]|[sS])$ ]]; then
        helm upgrade prometheus prometheus-community/kube-prometheus-stack \
          -n monitoring \
          -f k8s/monitoring/prometheus-values.yaml
        echo -e "${GREEN}✓ kube-prometheus-stack actualizado${NC}"
    else
        echo -e "${YELLOW}⚠️  Instalación saltada${NC}"
    fi
else
    helm install prometheus prometheus-community/kube-prometheus-stack \
      -n monitoring \
      -f k8s/monitoring/prometheus-values.yaml \
      --create-namespace
    echo -e "${GREEN}✓ kube-prometheus-stack instalado${NC}"
fi
echo ""

# Esperar a que los pods estén listos
echo -e "${YELLOW}Esperando a que los pods estén listos...${NC}"
kubectl wait --for=condition=ready pod \
  -l "app.kubernetes.io/instance=prometheus" \
  -n monitoring \
  --timeout=300s 2>/dev/null || true
echo -e "${GREEN}✓ Pods de monitoreo listos${NC}\n"

# Crear namespace de la aplicación si no existe
echo -e "${YELLOW}Verificando namespace 'tienda-online'...${NC}"
if kubectl get namespace tienda-online &> /dev/null; then
    echo -e "${GREEN}✓ Namespace 'tienda-online' existe${NC}"
else
    kubectl create namespace tienda-online
    echo -e "${GREEN}✓ Namespace 'tienda-online' creado${NC}"
fi
echo ""

# Aplicar ServiceMonitor
echo -e "${YELLOW}Aplicando ServiceMonitor...${NC}"
kubectl apply -f k8s/monitoring/servicemonitor.yaml
echo -e "${GREEN}✓ ServiceMonitor aplicado${NC}\n"

# Aplicar dashboard ConfigMap (opcional)
echo -e "${YELLOW}Aplicando dashboard de Grafana...${NC}"
kubectl apply -f k8s/monitoring/grafana-dashboard-configmap.yaml
echo -e "${GREEN}✓ Dashboard ConfigMap aplicado${NC}\n"

# Mostrar información de acceso
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Instalación completada${NC}"
echo -e "${GREEN}========================================${NC}\n"

echo -e "${BLUE}📊 Servicios instalados:${NC}"
echo -e "  ✓ Prometheus"
echo -e "  ✓ Grafana"
echo -e "  ✓ Alertmanager"
echo -e "  ✓ Node Exporter"
echo -e "  ✓ Kube State Metrics\n"

echo -e "${BLUE}🔍 Para acceder a los servicios:${NC}\n"

echo -e "${YELLOW}Prometheus:${NC}"
echo -e "  kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090"
echo -e "  URL: http://localhost:9090\n"

echo -e "${YELLOW}Grafana:${NC}"
echo -e "  kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80"
echo -e "  URL: http://localhost:3000"
echo -e "  Usuario: admin"
echo -e "  Password: admin123\n"

echo -e "${YELLOW}Alertmanager:${NC}"
echo -e "  kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-alertmanager 9093:9093"
echo -e "  URL: http://localhost:9093\n"

echo -e "${BLUE}📈 Verificar métricas del backend:${NC}"
echo -e "  kubectl port-forward -n tienda-online svc/tienda-backend 5000:5000"
echo -e "  curl http://localhost:5000/metrics\n"

echo -e "${BLUE}🧪 Generar tráfico para testing:${NC}"
echo -e "  ./scripts/generate-traffic.sh http://localhost:5000 http://localhost:8080 300\n"

echo -e "${GREEN}¡Listo! El monitoreo está configurado y funcionando.${NC}"

