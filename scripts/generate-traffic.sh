#!/bin/bash

# Script para generar tráfico a la aplicación Tienda Online
# Esto ayuda a poblar las métricas en Prometheus/Grafana

set -e

# Colores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Generador de Tráfico - Tienda Online${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Verificar si se proporcionó la URL base o usar la por defecto
BACKEND_URL="${1:-http://localhost:5000}"
FRONTEND_URL="${2:-http://localhost:3001}"

echo -e "${GREEN}Backend URL:${NC} $BACKEND_URL"
echo -e "${GREEN}Frontend URL:${NC} $FRONTEND_URL\n"

# Verificar conectividad
echo -e "${YELLOW}Verificando conectividad...${NC}"
if ! curl -s "$BACKEND_URL/health" > /dev/null; then
    echo -e "${YELLOW}⚠️  No se puede conectar al backend. Verifica que esté corriendo.${NC}"
    echo -e "Intenta con: kubectl port-forward -n tienda-online svc/backend-service 5000:5000"
    exit 1
fi
echo -e "${GREEN}✓ Conectividad OK${NC}\n"

# Duración del test en segundos (por defecto 5 minutos)
DURATION="${3:-300}"
INTERVAL=1

echo -e "${GREEN}Generando tráfico durante ${DURATION} segundos...${NC}\n"

# Contador de requests
COUNTER=0
START_TIME=$(date +%s)

while true; do
    CURRENT_TIME=$(date +%s)
    ELAPSED=$((CURRENT_TIME - START_TIME))
    
    if [ $ELAPSED -ge $DURATION ]; then
        break
    fi
    
    COUNTER=$((COUNTER + 1))
    
    # 1. Health check (10%)
    if [ $((COUNTER % 10)) -eq 0 ]; then
        curl -s "$BACKEND_URL/health" > /dev/null
        echo -e "[$(date +%H:%M:%S)] ${BLUE}Health check${NC}"
    fi
    
    # 2. Consultar todos los productos (30%)
    if [ $((COUNTER % 3)) -eq 0 ]; then
        curl -s "$BACKEND_URL/api/productos" > /dev/null
        echo -e "[$(date +%H:%M:%S)] ${GREEN}GET /api/productos${NC}"
    fi
    
    # 3. Consultar un producto específico (30%)
    if [ $((COUNTER % 3)) -eq 1 ]; then
        PRODUCT_ID=$((RANDOM % 10 + 1))
        curl -s "$BACKEND_URL/api/productos/$PRODUCT_ID" > /dev/null
        echo -e "[$(date +%H:%M:%S)] ${GREEN}GET /api/productos/${PRODUCT_ID}${NC}"
    fi
    
    # 4. Crear un pedido (20%)
    if [ $((COUNTER % 5)) -eq 0 ]; then
        # Generar datos aleatorios para el pedido
        PRODUCT_ID=$((RANDOM % 20 + 1))
        CANTIDAD=$((RANDOM % 3 + 1))
        PRECIO=$((RANDOM % 1000 + 50))
        TOTAL=$((PRECIO * CANTIDAD))
        
        PEDIDO_DATA=$(cat <<EOF
{
  "cliente_nombre": "Cliente Test $COUNTER",
  "cliente_email": "test$COUNTER@example.com",
  "productos": [
    {
      "producto_id": $PRODUCT_ID,
      "cantidad": $CANTIDAD,
      "precio": $PRECIO
    }
  ],
  "total": $TOTAL
}
EOF
)
        
        curl -s -X POST \
          -H "Content-Type: application/json" \
          -d "$PEDIDO_DATA" \
          "$BACKEND_URL/api/pedidos" > /dev/null
        echo -e "[$(date +%H:%M:%S)] ${YELLOW}POST /api/pedidos (producto: $PRODUCT_ID, cantidad: $CANTIDAD)${NC}"
    fi
    
    # 5. Acceder al frontend (10%)
    if [ $((COUNTER % 10)) -eq 5 ]; then
        curl -s "$FRONTEND_URL" > /dev/null
        echo -e "[$(date +%H:%M:%S)] ${BLUE}GET frontend${NC}"
    fi
    
    # 6. Métricas (cada 20 requests)
    if [ $((COUNTER % 20)) -eq 0 ]; then
        curl -s "$BACKEND_URL/metrics" > /dev/null
        echo -e "[$(date +%H:%M:%S)] ${BLUE}GET /metrics${NC}"
    fi
    
    # Mostrar progreso cada 10 segundos
    if [ $((ELAPSED % 10)) -eq 0 ] && [ $((ELAPSED % 10)) -lt 2 ]; then
        REMAINING=$((DURATION - ELAPSED))
        echo -e "\n${GREEN}Progreso: ${ELAPSED}s / ${DURATION}s (${REMAINING}s restantes)${NC}"
        echo -e "${GREEN}Total requests: ${COUNTER}${NC}\n"
    fi
    
    # Esperar antes del siguiente request
    sleep $INTERVAL
done

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}  Generación de tráfico completada${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Total requests enviados: ${COUNTER}${NC}"
echo -e "${GREEN}Duración: ${DURATION} segundos${NC}"
echo -e "${GREEN}Promedio: $((COUNTER / DURATION)) req/s${NC}\n"

echo -e "${BLUE}Ahora puedes revisar las métricas en:${NC}"
echo -e "  - Prometheus: kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090"
echo -e "    URL: http://localhost:9090"
echo -e "  - Grafana: kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80"
echo -e "    URL: http://localhost:3000 (admin/admin123)"
echo -e "\n${YELLOW}Tip: El dashboard 'Tienda Online - Monitoreo' debería estar disponible automáticamente en Grafana${NC}"

