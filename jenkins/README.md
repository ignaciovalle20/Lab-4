# Jenkins - CI/CD Pipeline

Este directorio contiene la configuración de Jenkins para el pipeline de CI/CD del Laboratorio 4.

## 📁 Archivos

- **`Dockerfile`**: Imagen personalizada de Jenkins con Docker, kubectl, Helm, Semgrep y Snyk
- **`docker-compose.yml`**: Configuración para ejecutar Jenkins con Docker Compose
- **`plugins.txt`**: Lista de plugins de Jenkins a instalar
- **`init.groovy.d/`**: Scripts de inicialización automática de Jenkins
  - `01-admin-user.groovy`: Crea usuario admin
  - `02-disable-setup-wizard.groovy`: Deshabilita el wizard de setup
  - `03-configure-tools.groovy`: Configura herramientas (Node.js, etc.)

## 🚀 Inicio Rápido

### Opción 1: Script automatizado (recomendado)

```bash
./scripts/jenkins-start.sh
```

Este script:
- ✅ Verifica que Docker esté corriendo
- ✅ Construye la imagen de Jenkins
- ✅ Inicia Jenkins con docker-compose
- ✅ Espera a que Jenkins esté listo
- ✅ Muestra información de acceso

### Opción 2: Manual con Docker Compose

```bash
# Cambiar al directorio jenkins
cd jenkins

# Construir la imagen
docker-compose build

# Iniciar Jenkins
docker-compose up -d

# Ver logs
docker logs -f jenkins-lab4
```

## 🔑 Acceso

Una vez que Jenkins esté corriendo:

- **URL**: http://localhost:8080
- **Usuario**: `admin`
- **Password**: `admin123`

## 🔧 Herramientas Incluidas

La imagen de Jenkins incluye las siguientes herramientas preinstaladas:

### 1. Docker CLI
Para construir y publicar imágenes Docker en el pipeline.

```bash
docker build -t myimage:tag .
docker push myimage:tag
```

### 2. kubectl
Para interactuar con clusters de Kubernetes.

```bash
kubectl get pods
kubectl apply -f deployment.yaml
```

### 3. Helm
Para desplegar aplicaciones con Helm charts.

```bash
helm install myapp ./chart
helm upgrade myapp ./chart
```

### 4. Semgrep
Para análisis estático de código (SAST).

```bash
semgrep --config=auto backend/
```

### 5. Snyk
Para escaneo de dependencias y vulnerabilidades.

```bash
snyk test
snyk monitor
```

## 🔨 Configuración Adicional

### 1. Configurar Credenciales

#### Docker Hub
1. Ir a: Manage Jenkins → Manage Credentials
2. Agregar credencial tipo "Username with password"
3. ID: `dockerhub-credentials`
4. Username: tu usuario de Docker Hub
5. Password: tu password o access token

#### Kubeconfig
1. Ir a: Manage Jenkins → Manage Credentials
2. Agregar credencial tipo "Secret file"
3. ID: `kubeconfig`
4. File: tu archivo `~/.kube/config`

#### Snyk Token
1. Obtener token desde: https://app.snyk.io/account
2. Ir a: Manage Jenkins → Manage Credentials
3. Agregar credencial tipo "Secret text"
4. ID: `snyk-token`
5. Secret: tu token de Snyk

### 2. Configurar Git Repository

1. Ir a: New Item → Pipeline
2. Nombre: `tienda-online-pipeline`
3. Pipeline definition: "Pipeline script from SCM"
4. SCM: Git
5. Repository URL: tu repositorio
6. Branch: `main` o `master`
7. Script Path: `Jenkinsfile`

### 3. Configurar Webhooks (opcional)

Para builds automáticos al hacer push:

#### GitHub
1. Ir a: Repository → Settings → Webhooks
2. Payload URL: `http://tu-jenkins:8080/github-webhook/`
3. Content type: `application/json`
4. Events: "Just the push event"

#### GitLab
1. Ir a: Repository → Settings → Webhooks
2. URL: `http://tu-jenkins:8080/project/tienda-online-pipeline`
3. Events: "Push events"

## 📊 Métricas de Prometheus

Jenkins expone métricas en: `http://localhost:8080/prometheus/`

Estas métricas incluyen:
- Número de jobs
- Duración de builds
- Tasa de éxito/fallo
- Queue length
- Executor usage

## 🧪 Testing del Pipeline

### 1. Crear un Job de prueba

```groovy
pipeline {
    agent any
    stages {
        stage('Test Tools') {
            steps {
                sh 'docker --version'
                sh 'kubectl version --client'
                sh 'helm version'
                sh 'semgrep --version'
                sh 'snyk --version'
            }
        }
    }
}
```

### 2. Ejecutar

1. Ir a Jenkins → New Item
2. Nombre: `test-tools`
3. Tipo: Pipeline
4. En "Pipeline script" pegar el código anterior
5. Save y "Build Now"

## 🛠️ Troubleshooting

### Jenkins no inicia

```bash
# Ver logs
docker logs jenkins-lab4

# Verificar si el puerto 8080 está en uso
lsof -i :8080

# Reiniciar Jenkins
cd jenkins && docker-compose restart
```

### Error de permisos con Docker

El usuario `jenkins` debe tener acceso al socket de Docker:

```bash
# Entrar al contenedor
docker exec -it jenkins-lab4 bash

# Verificar permisos
ls -la /var/run/docker.sock

# Si es necesario, cambiar permisos (temporal)
chmod 666 /var/run/docker.sock
```

### Kubectl no encuentra el cluster

Asegurarte de que el contexto de kubectl esté en Minikube:

```bash
# En tu máquina host
kubectl config use-context minikube

# Verificar en Jenkins
docker exec jenkins-lab4 kubectl config current-context
```

### Plugins no se instalan

```bash
# Reconstruir la imagen
cd jenkins && docker-compose build --no-cache

# Reiniciar
docker-compose up -d
```

### Semgrep o Snyk no funcionan

```bash
# Entrar al contenedor
docker exec -it jenkins-lab4 bash

# Verificar instalación
which semgrep
which snyk

# Verificar versiones
semgrep --version
snyk --version
```

## 🧹 Limpieza

### Detener Jenkins

```bash
cd jenkins && docker-compose down
```

### Detener y eliminar datos

```bash
cd jenkins && docker-compose down -v
```

### Eliminar imagen

```bash
docker rmi jenkins-lab4
```

## 📚 Referencias

- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [Jenkins Pipeline](https://www.jenkins.io/doc/book/pipeline/)
- [Docker Pipeline Plugin](https://plugins.jenkins.io/docker-workflow/)
- [Kubernetes Plugin](https://plugins.jenkins.io/kubernetes/)
- [Configuration as Code](https://github.com/jenkinsci/configuration-as-code-plugin)
- [Semgrep](https://semgrep.dev/docs/)
- [Snyk CLI](https://docs.snyk.io/snyk-cli)

## 🎯 Próximos Pasos

1. ✅ Jenkins instalado y configurado
2. ⏳ Crear Jenkinsfile con pipeline completo
3. ⏳ Configurar credenciales
4. ⏳ Ejecutar primer pipeline
5. ⏳ Configurar webhooks para CI/CD automático

