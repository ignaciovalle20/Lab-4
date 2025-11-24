#!/bin/bash

# Script para iniciar Jenkins con Docker Compose
# Uso: ./scripts/jenkins-start.sh

set -e

# Colores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Iniciando Jenkins${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Verificar si Docker está corriendo
if ! docker ps &> /dev/null; then
    echo -e "${RED}❌ Docker no está corriendo${NC}"
    echo -e "${YELLOW}Inicia Docker y vuelve a intentar${NC}"
    exit 1
fi

# Verificar si docker-compose está instalado
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}❌ docker-compose no está instalado${NC}"
    exit 1
fi

# Cambiar al directorio jenkins
cd "$(dirname "$0")/../jenkins"

# Verificar si Jenkins ya está corriendo
if docker ps | grep -q jenkins-lab4; then
    echo -e "${YELLOW}⚠️  Jenkins ya está corriendo${NC}"
    echo -e "${YELLOW}¿Deseas reiniciarlo? (s/n)${NC}"
    read -r response
    if [[ "$response" =~ ^([sS][iI]|[sS])$ ]]; then
        echo -e "${YELLOW}Deteniendo Jenkins...${NC}"
        docker-compose down
    else
        echo -e "${GREEN}Jenkins sigue corriendo en http://localhost:8080${NC}"
        exit 0
    fi
fi

# Construir la imagen de Jenkins
echo -e "${YELLOW}Construyendo imagen de Jenkins...${NC}"
docker-compose build

# Iniciar Jenkins
echo -e "${YELLOW}Iniciando Jenkins...${NC}"
docker-compose up -d

# Esperar a que Jenkins esté listo
echo -e "${YELLOW}Esperando a que Jenkins esté listo...${NC}"
echo -e "${BLUE}Esto puede tomar 1-2 minutos...${NC}\n"

RETRIES=60
COUNT=0
until curl -s http://localhost:8080/login > /dev/null; do
    COUNT=$((COUNT + 1))
    if [ $COUNT -ge $RETRIES ]; then
        echo -e "${RED}❌ Jenkins no respondió después de ${RETRIES} intentos${NC}"
        echo -e "${YELLOW}Revisa los logs con: docker logs jenkins-lab4${NC}"
        exit 1
    fi
    echo -e "${YELLOW}Esperando... (intento $COUNT/$RETRIES)${NC}"
    sleep 2
done

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}  Jenkins está listo!${NC}"
echo -e "${GREEN}========================================${NC}\n"

echo -e "${BLUE}📋 Información de acceso:${NC}"
echo -e "  URL: ${GREEN}http://localhost:8080${NC}"
echo -e "  Usuario: ${GREEN}admin${NC}"
echo -e "  Password: ${GREEN}admin123${NC}\n"

echo -e "${BLUE}🔧 Comandos útiles:${NC}"
echo -e "  Ver logs:        ${YELLOW}docker logs -f jenkins-lab4${NC}"
echo -e "  Detener:         ${YELLOW}cd jenkins && docker-compose down${NC}"
echo -e "  Reiniciar:       ${YELLOW}cd jenkins && docker-compose restart${NC}"
echo -e "  Ver estado:      ${YELLOW}docker ps | grep jenkins${NC}\n"

echo -e "${BLUE}📦 Plugins instalados:${NC}"
echo -e "  ✓ Git & GitHub"
echo -e "  ✓ Docker Pipeline"
echo -e "  ✓ Kubernetes CLI"
echo -e "  ✓ BlueOcean (UI moderna)"
echo -e "  ✓ Prometheus (métricas)"
echo -e "  ✓ Configuration as Code\n"

echo -e "${BLUE}🔨 Herramientas disponibles:${NC}"
echo -e "  ✓ Docker CLI"
echo -e "  ✓ kubectl"
echo -e "  ✓ Helm"
echo -e "  ✓ Semgrep"
echo -e "  ✓ Snyk\n"

echo -e "${GREEN}¡Jenkins está listo para usar!${NC}"
echo -e "${YELLOW}Abre http://localhost:8080 en tu navegador${NC}\n"

# Abrir navegador automáticamente (solo en macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo -e "${BLUE}Abriendo navegador...${NC}"
    sleep 2
    open http://localhost:8080
fi

