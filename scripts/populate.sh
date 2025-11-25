#!/bin/bash

# populate.sh - Script para poblar la base de datos con datos de prueba
# y generar tráfico inicial para las métricas

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
print_header "         POBLAR BASE DE DATOS - TIENDA ONLINE              "
echo ""

# Verificar que el backend esté corriendo
print_step "Verificando que el backend esté corriendo..."
if ! kubectl get pods -n tienda-online -l app.kubernetes.io/component=backend | grep -q "Running"; then
    print_error "El backend no está corriendo. Ejecuta ./scripts/init.sh primero"
    exit 1
fi
print_success "Backend está corriendo"
echo ""

# Obtener el nombre del pod del backend
BACKEND_POD=$(kubectl get pods -n tienda-online -l app.kubernetes.io/component=backend -o jsonpath='{.items[0].metadata.name}')
print_step "Pod del backend: $BACKEND_POD"
echo ""

# Verificar conexión a la base de datos
print_header "PASO 1: Verificando conexión a la base de datos"
echo ""

print_step "Esperando a que MySQL esté listo..."
for i in {1..30}; do
    if kubectl exec -n tienda-online $BACKEND_POD -- nc -z mysql-service 3306 2>/dev/null; then
        print_success "MySQL está listo"
        break
    fi
    if [ $i -eq 30 ]; then
        print_error "Timeout esperando a MySQL"
        exit 1
    fi
    sleep 2
done
echo ""

# Port forward del backend para hacer requests HTTP
print_header "PASO 2: Configurando port forward"
echo ""

print_step "Iniciando port forward del backend..."
kubectl port-forward -n tienda-online svc/backend-service 5000:5000 &
PF_PID=$!
sleep 3
print_success "Port forward activo (PID: $PF_PID)"
echo ""

# Función para limpiar al salir
cleanup() {
    print_step "Limpiando port forward..."
    kill $PF_PID 2>/dev/null || true
    print_success "Port forward cerrado"
}
trap cleanup EXIT

# Verificar que el backend responda
print_step "Verificando que el backend responda..."
for i in {1..10}; do
    if curl -s http://localhost:5000/health > /dev/null 2>&1; then
        print_success "Backend responde correctamente"
        break
    fi
    if [ $i -eq 10 ]; then
        print_error "Backend no responde"
        exit 1
    fi
    sleep 1
done
echo ""

# Poblar productos
print_header "PASO 3: Poblando productos"
echo ""

PRODUCTOS=(
    '{"nombre": "Laptop Dell XPS 15", "descripcion": "Laptop profesional de alto rendimiento con procesador Intel i7", "precio": 1299.99, "stock": 15, "categoria": "Computadoras"}'
    '{"nombre": "iPhone 14 Pro", "descripcion": "Smartphone Apple con cámara de 48MP y chip A16 Bionic", "precio": 999.99, "stock": 30, "categoria": "Smartphones"}'
    '{"nombre": "Samsung Galaxy S23", "descripcion": "Smartphone Android con pantalla AMOLED de 6.1 pulgadas", "precio": 799.99, "stock": 25, "categoria": "Smartphones"}'
    '{"nombre": "iPad Air", "descripcion": "Tablet Apple con chip M1 y pantalla Liquid Retina", "precio": 599.99, "stock": 20, "categoria": "Tablets"}'
    '{"nombre": "MacBook Pro 14", "descripcion": "Laptop profesional con chip M2 Pro", "precio": 1999.99, "stock": 10, "categoria": "Computadoras"}'
    '{"nombre": "AirPods Pro", "descripcion": "Audífonos inalámbricos con cancelación de ruido", "precio": 249.99, "stock": 50, "categoria": "Audio"}'
    '{"nombre": "Sony WH-1000XM5", "descripcion": "Audífonos over-ear con la mejor cancelación de ruido", "precio": 399.99, "stock": 35, "categoria": "Audio"}'
    '{"nombre": "Apple Watch Series 8", "descripcion": "Smartwatch con monitoreo de salud avanzado", "precio": 399.99, "stock": 40, "categoria": "Wearables"}'
    '{"nombre": "Samsung Monitor 27", "descripcion": "Monitor 4K UHD de 27 pulgadas para productividad", "precio": 349.99, "stock": 22, "categoria": "Monitores"}'
    '{"nombre": "Logitech MX Master 3", "descripcion": "Mouse inalámbrico ergonómico para profesionales", "precio": 99.99, "stock": 60, "categoria": "Accesorios"}'
    '{"nombre": "Teclado Mecánico Keychron", "descripcion": "Teclado mecánico compacto 75% con switches hot-swap", "precio": 89.99, "stock": 45, "categoria": "Accesorios"}'
    '{"nombre": "Webcam Logitech C920", "descripcion": "Webcam Full HD 1080p para videoconferencias", "precio": 79.99, "stock": 55, "categoria": "Accesorios"}'
    '{"nombre": "SSD Samsung 1TB", "descripcion": "Disco sólido NVMe M.2 de 1TB con velocidades de hasta 7000 MB/s", "precio": 129.99, "stock": 70, "categoria": "Almacenamiento"}'
    '{"nombre": "Disco Externo 2TB", "descripcion": "Disco duro portátil USB 3.0 de 2TB", "precio": 79.99, "stock": 65, "categoria": "Almacenamiento"}'
    '{"nombre": "Router TP-Link WiFi 6", "descripcion": "Router de alta velocidad con WiFi 6 y cobertura extendida", "precio": 149.99, "stock": 30, "categoria": "Redes"}'
    '{"nombre": "Nintendo Switch OLED", "descripcion": "Consola de videojuegos híbrida con pantalla OLED", "precio": 349.99, "stock": 18, "categoria": "Gaming"}'
    '{"nombre": "PlayStation 5", "descripcion": "Consola de videojuegos de última generación", "precio": 499.99, "stock": 12, "categoria": "Gaming"}'
    '{"nombre": "Xbox Series X", "descripcion": "Consola Xbox con soporte para 4K y 120fps", "precio": 499.99, "stock": 15, "categoria": "Gaming"}'
    '{"nombre": "Kindle Paperwhite", "descripcion": "Lector de libros electrónicos con pantalla de 6.8 pulgadas", "precio": 139.99, "stock": 40, "categoria": "Electrónica"}'
    '{"nombre": "GoPro HERO11", "descripcion": "Cámara de acción 5.3K con estabilización avanzada", "precio": 399.99, "stock": 28, "categoria": "Cámaras"}'
)

PRODUCT_COUNT=0
for producto in "${PRODUCTOS[@]}"; do
    print_step "Creando producto $(($PRODUCT_COUNT + 1))/${#PRODUCTOS[@]}..."
    RESPONSE=$(curl -s -X POST http://localhost:5000/api/productos \
        -H "Content-Type: application/json" \
        -d "$producto")
    
    if echo "$RESPONSE" | grep -q "id"; then
        print_success "Producto creado exitosamente"
        PRODUCT_COUNT=$((PRODUCT_COUNT + 1))
    else
        print_warning "Error al crear producto (posiblemente ya existe)"
    fi
    sleep 0.5
done

echo ""
print_success "Total de productos creados: $PRODUCT_COUNT"
echo ""

# Generar consultas de productos
print_header "PASO 4: Generando consultas de productos"
echo ""

print_step "Consultando lista de productos 10 veces..."
for i in {1..10}; do
    curl -s http://localhost:5000/api/productos > /dev/null
    echo -n "."
    sleep 0.5
done
echo ""
print_success "Consultas completadas"
echo ""

print_step "Consultando productos individuales..."
for i in {1..20}; do
    PRODUCT_ID=$((RANDOM % 20 + 1))
    curl -s http://localhost:5000/api/productos/$PRODUCT_ID > /dev/null 2>&1 || true
    echo -n "."
    sleep 0.3
done
echo ""
print_success "Consultas individuales completadas"
echo ""

# Crear algunos pedidos de prueba
print_header "PASO 5: Creando pedidos de prueba"
echo ""

CLIENTES=(
    "Juan Pérez|juan@example.com"
    "María García|maria@example.com"
    "Carlos López|carlos@example.com"
    "Ana Martínez|ana@example.com"
    "Pedro Rodríguez|pedro@example.com"
    "Laura Fernández|laura@example.com"
    "Diego Sánchez|diego@example.com"
    "Sofia Torres|sofia@example.com"
    "Miguel Ramírez|miguel@example.com"
    "Valentina Castro|valentina@example.com"
)

ORDER_COUNT=0
for cliente_info in "${CLIENTES[@]}"; do
    IFS='|' read -r nombre email <<< "$cliente_info"
    
    # Crear un pedido con 1-3 productos aleatorios
    NUM_ITEMS=$((RANDOM % 3 + 1))
    ITEMS="["
    TOTAL=0
    
    for ((j=0; j<NUM_ITEMS; j++)); do
        PRODUCT_ID=$((RANDOM % 20 + 1))
        CANTIDAD=$((RANDOM % 3 + 1))
        PRECIO=$((RANDOM % 1000 + 50))
        
        if [ $j -gt 0 ]; then
            ITEMS="$ITEMS,"
        fi
        ITEMS="$ITEMS{\"productoId\":$PRODUCT_ID,\"cantidad\":$CANTIDAD,\"precioUnitario\":$PRECIO}"
        TOTAL=$((TOTAL + PRECIO * CANTIDAD))
    done
    ITEMS="$ITEMS]"
    
    PEDIDO="{\"cliente\":\"$nombre\",\"email\":\"$email\",\"direccion\":\"Calle Falsa 123\",\"items\":$ITEMS,\"total\":$TOTAL}"
    
    print_step "Creando pedido para $nombre..."
    RESPONSE=$(curl -s -X POST http://localhost:5000/api/pedidos \
        -H "Content-Type: application/json" \
        -d "$PEDIDO")
    
    if echo "$RESPONSE" | grep -q "id"; then
        print_success "Pedido creado exitosamente"
        ORDER_COUNT=$((ORDER_COUNT + 1))
    else
        print_warning "Error al crear pedido"
    fi
    sleep 0.5
done

echo ""
print_success "Total de pedidos creados: $ORDER_COUNT"
echo ""

# Resumen final
print_header "RESUMEN"
echo ""

print_success "Base de datos poblada exitosamente"
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "                         RESUMEN                            "
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "📦 Productos creados: $PRODUCT_COUNT"
echo "🛒 Pedidos creados: $ORDER_COUNT"
echo "📊 Consultas HTTP generadas: ~30"
echo ""
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "💡 PRÓXIMOS PASOS:"
echo ""
echo "1. Ver métricas en Prometheus:"
echo "   kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090"
echo "   Abrir: http://localhost:9090"
echo ""
echo "2. Ver dashboard en Grafana:"
echo "   kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80"
echo "   Abrir: http://localhost:3000 (admin/admin123)"
echo ""
echo "3. Generar más tráfico:"
echo "   ./scripts/generate-traffic.sh"
echo ""
echo "4. Ver la aplicación:"
echo "   kubectl port-forward -n tienda-online svc/tienda-frontend 3001:80"
echo "   Abrir: http://localhost:3001"
echo ""
print_success "Población completada ✨"
echo ""

